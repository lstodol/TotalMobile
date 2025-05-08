param tenantId string
param keyVaultUri string
param dbxWorkspaceId string
param dbxWorkspaceUrl string
param keyVaultName string
param keyVaultId string
param saName string
param rgName string
param servicePrincipalId string
param servicePrincipalKey string
param networkSecurityGroupName string
param dataSharingStorages string
param eventHubNamespaceName string
@secure()
param awsGatewaySharedKey string
@secure()
param encodedProductteamWarehouseConnectionProps string
param includeAWSResources bool

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}

resource secretTenantId 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'tenant-id'
  properties: {
    value: tenantId
  }
}

resource vaultUri 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'key-vault-uri'
  properties: {
    value: keyVaultUri
  }
}

resource vaultId 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = {
  parent: keyVault
  name: 'key-vault-id'
  properties: {
    value: keyVaultId
  }
}

resource dbxWorkspaceSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'dbx-workspace-id'
  properties: {
    value: dbxWorkspaceId
  }
}

resource dbxWorkspaceUri 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = {
  parent: keyVault
  name: 'dbx-workspace-url'
  properties: {
    value: dbxWorkspaceUrl
  }
}

resource storageAccountName 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = {
  parent: keyVault
  name: 'storage-account-name'
  properties: {
    value: saName
  }
}

resource dataSharingStoragesSecret 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = {
  parent: keyVault
  name: 'data-sharing-storages'
  properties: {
    value: dataSharingStorages
  }
}


resource resourceGroupName 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = {
  parent: keyVault
  name: 'resource-group-name'
  properties: {
    value: rgName
  }
}

resource servicePrincipalIdName 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = {
  parent: keyVault
  name: 'service-principal-id'
  properties: {
    value: servicePrincipalId
  }
}

resource servicePrincipalKeyName 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = {
  parent: keyVault
  name: 'service-principal-key'
  properties: {
    value: servicePrincipalKey
  }
}

resource networkSecurityGroup 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = {
  parent: keyVault
  name: 'network-security-group'
  properties: {
    value: networkSecurityGroupName
  }
}

resource eventHubNamespace 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = {
  parent: keyVault
  name: 'event-hub-namespace-name'
  properties: {
    value: eventHubNamespaceName
  }
}

resource awsTransitGatewayKey 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = if (includeAWSResources) {
  parent: keyVault
  name: 'aws-transit-gateway-key'
  properties: {
    value: awsGatewaySharedKey
  }
}

resource productteamConnectionProperies 'Microsoft.KeyVault/vaults/secrets@2023-02-01'  = if (includeAWSResources) {
  parent: keyVault
  name: 'productteam-warehouse-connection-properties'
  properties: {
    value: encodedProductteamWarehouseConnectionProps
  }
}
