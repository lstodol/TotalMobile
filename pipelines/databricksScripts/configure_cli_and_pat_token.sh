#!/bin/sh
url=$1
access_token=$2

authHeader="Authorization: Bearer $access_token"

pat_token_config=$(jq -n -c --arg ls "3600" --arg co "DevOps Token" '{lifetime_seconds: ($ls|tonumber), comment: $co}')
pat_token_response=$(echo "$pat_token_config" | curl -sS -X POST -H "$authHeader" --data-binary "@-" "https://$url/api/2.0/token/create")

pat_token=`echo $pat_token_response | jq -r .token_value`

curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh > ~/dbx_log.txt
echo "[DEFAULT]
host  = https://$url
token = $pat_token" > ~/.databrickscfg

echo $pat_token 