param location string 
param tags object
param eventHubNameSpace string
@description('Specifies the messaging tier for Event Hub Namespace.')
@allowed(['Basic','Standard','Premium'])
param eventHubSku string = 'Standard'
param hostSubnetId string 
param containerSubnetId string 
param hotPathEntities array
param keyVaultName string
param analyticsAdapterPrimarySubnetId string
param analyticsAdapterSecondarySubnetId string

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: eventHubNameSpace
  location: location
  tags: tags
  sku: {
    name: eventHubSku
    tier: eventHubSku
    capacity: 1
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
    zoneRedundant: true
    minimumTlsVersion:'1.2'
    publicNetworkAccess:'Disabled'
  }
}

resource eventHubNamespaceNetworking 'Microsoft.EventHub/namespaces/networkRuleSets@2024-01-01' = {
  parent: eventHubNamespace
  name: 'default'
  properties: {
    publicNetworkAccess:'Enabled'
    defaultAction:'Deny'
    virtualNetworkRules: [
      {
        ignoreMissingVnetServiceEndpoint: false
        subnet: {
          id: hostSubnetId
        }
      }
      {
        ignoreMissingVnetServiceEndpoint: false
        subnet: {
          id: containerSubnetId
        }
      }
      {
        ignoreMissingVnetServiceEndpoint: false
        subnet: {
          id: analyticsAdapterPrimarySubnetId
        }
      }
      analyticsAdapterSecondarySubnetId != '' ? {
        ignoreMissingVnetServiceEndpoint: false
        subnet: {
          id: analyticsAdapterSecondarySubnetId
        }
      } : {
        ignoreMissingVnetServiceEndpoint: false
        subnet: {
          id: analyticsAdapterPrimarySubnetId
        }
      }
    ]
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = [for entity in hotPathEntities: {
  parent: eventHubNamespace
  name: '${entity}-evh'
  properties: {
    messageRetentionInDays: 7
    partitionCount: 1
    }
  }
]

resource sasListenPolicy 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2024-01-01' = [for (entity, index) in hotPathEntities: {
  parent: eventHub[index]
  name: 'sas-${entity}-listen-evh'
  properties: {
    rights: [
      'Listen'
    ]
  }
}]

resource sasSendPolicy 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2024-01-01' = [for (entity, index) in hotPathEntities: {
  parent: eventHub[index]
  name: 'sas-${entity}-send-evh'
  properties: {
    rights: [
      'Send'
    ]
  }
}]

resource keyVault 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {
  name: keyVaultName
}

resource kvSecretListenPolicy 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = [for (entity, index) in hotPathEntities: {
  parent: keyVault
  name: 'sas-${eventHubNamespace.name}-${entity}-listen-evh-connection'
  properties: {
    value: 'Endpoint=sb://${eventHubNamespace.name}.servicebus.windows.net/;SharedAccessKeyName=sas-${entity}-listen-evh;SharedAccessKey=${listKeys(sasListenPolicy[index].id, '2024-01-01').primaryKey};EntityPath=${entity}-evh'
  }
}]

resource kvSecretSendPolicy 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' = [for (entity, index) in hotPathEntities: {
  parent: keyVault
  name: 'sas-${eventHubNamespace.name}-${entity}-send-evh-connection'
  properties: {
    value: 'Endpoint=sb://${eventHubNamespace.name}.servicebus.windows.net/;SharedAccessKeyName=sas-${entity}-send-evh;SharedAccessKey=${listKeys(sasSendPolicy[index].id, '2024-01-01').primaryKey};EntityPath=${entity}-evh'
  }
}]

output eventHubNamespaceId string = eventHubNamespace.id
output eventHubNamespaceName string = eventHubNamespace.name
