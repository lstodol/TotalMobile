param keyVaultName string
param location string 
param tags object
param tenantId string
param skuName string = 'premium'
param accessPolicies array
param hostSubnetId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    enabledForTemplateDeployment: false
    enabledForDeployment: false

    softDeleteRetentionInDays: 7
    tenantId: tenantId
    accessPolicies: [
      for policy in accessPolicies: {
        objectId: policy.objectId
        tenantId: tenantId
        permissions: policy.permissions
      }
    ]
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: hostSubnetId
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
