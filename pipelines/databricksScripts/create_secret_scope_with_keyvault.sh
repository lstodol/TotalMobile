#!/bin/sh
scope_name=$1
key_vault_id=$2
key_vault_uri=$3

# Create Databricks Secret Scope if not exists
existing_scopes=$(databricks secrets list-scopes --output JSON)
echo 'Existing scopes:' $existing_scopes
echo 'size of scopes:' ${#existing_scopes} 

if [ "${existing_scopes:-0}" == 'null' ] || [ ${#existing_scopes} -lt 9 ] || [ "${existing_scopes:-0}" == *'"name":"$scope_name"'* ]; then 
    echo "Creating the secret scope..."
    echo $scope_name
    echo $key_vault_id
    echo $key_vault_uri
    databricks secrets create-scope --json "{\"scope\": \"$scope_name\", \"scope_backend_type\": \"AZURE_KEYVAULT\", \"initial_manage_principal\": \"users\", \"backend_azure_keyvault\": { \"resource_id\": \"$key_vault_id\", \"dns_name\": \"$key_vault_uri\" } }"
    echo "Secret scope '$scope_name' created."
else
    echo "The secret scope '$scope_name' already exists. No action has been taken."
fi