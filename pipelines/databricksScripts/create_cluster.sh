#!/bin/sh
cluster_config=$1
workspace_url=$2
databricks_token=$3

cluster_name=$4

if [ -z "${cluster_name}" ]; then
    cluster_name=$(jq -r '.cluster_name' $cluster_config)
fi

cluster_info=$(databricks clusters list | grep -i $cluster_name)
if [[ ! -z ${cluster_info} ]] && [[ $(echo $cluster_info | wc -l) = 1 ]];  then
    cluster_id=${cluster_info:0:20}
    echo "Cluster exists with ID: $cluster_id, so lets edit it."
    jq --arg propValue "$cluster_id" '. + {"cluster_id": $propValue }' $cluster_config > tmp.json && mv tmp.json $cluster_config
    echo "Starting cluster for edit"
    databricks clusters start $cluster_id
    echo "Editing cluster"
    databricks clusters edit --json @$cluster_config
else
    echo "cluster does not exist, lets create it"
    echo 'creating cluster with below config'
    cat $cluster_config
    cluster_info=$(databricks clusters create --cluster-name $cluster_name --json @$cluster_config)
    cluster_id=$(echo $cluster_info |  jq -r .cluster_id )
    echo "Cluster created with ID: $cluster_id"
    jq --arg propValue "$cluster_id" '. + {"cluster_id": $propValue }' $cluster_config > tmp.json && mv tmp.json $cluster_config
fi

echo "Installing libraries to it" 
cat $cluster_config


# Install libraries using the Databricks API
curl --header "Authorization: Bearer $databricks_token" --request POST \
 "https://$workspace_url/api/2.0/libraries/install" \
 --data "@$cluster_config"

