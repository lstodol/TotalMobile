targetScope = 'resourceGroup'

param dbxWorkspaceName string
param location string 
param pricingTier string = 'premium'
param vnetId string
param hostSubnetName string 
param containerSubnetName string 
param logAnalyticsWorkspaceId string
param tags object

@description('Specifies whether to deploy Azure Databricks workspace with Secure Cluster Connectivity (No Public IP) enabled or not')
param disablePublicIp bool = true

var managedResourceGroupName = '${dbxWorkspaceName}-${uniqueString(dbxWorkspaceName, resourceGroup().id)}'

resource workspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: dbxWorkspaceName
  location: location
  tags: tags
  sku: {
    name: pricingTier
  }
  properties: {
    managedResourceGroupId: managedResourceGroup.id
    parameters: {
      enableNoPublicIp: {
        value: disablePublicIp
      }
      customVirtualNetworkId: {
        value: vnetId
      }
      //a host subnet
      customPublicSubnetName: {
        value: hostSubnetName
      }
      //a container subnet
      customPrivateSubnetName: {
        value: containerSubnetName
      }
    }
  }
}

resource databricksDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${dbxWorkspaceName}-diagnosticSettings'
  scope: workspace
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

resource managedResourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' existing = {
  scope: subscription()
  name: managedResourceGroupName
}


output workspaceObject object = workspace.properties
output databricksWorkspaceId string = workspace.properties.workspaceId
output databricksWorkspaceUrl string = workspace.properties.workspaceUrl
output databricksDbfsStorageAccountName string = workspace.properties.parameters.storageAccountName.value

