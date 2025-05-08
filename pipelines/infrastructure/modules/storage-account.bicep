param tags object
param environment string
param location string
param storageAccountName string
param containerSubnetId string
param hostSubnetId string

var storageAccountSku = (environment == 'prod') ? 'Standard_RAGZRS' : 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: storageAccountSku
  }
  kind: 'StorageV2'
  properties: {
    networkAcls: {
      bypass: 'None'
      virtualNetworkRules: [
        {
          id: containerSubnetId
          action: 'Allow'
        }
        {
          id: hostSubnetId
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource configContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'config'
  parent: blobService
}

resource logsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'logs'
  parent: blobService
}

output storageAccountName string = storageAccountName
output storageAccountId string = storageAccount.id
