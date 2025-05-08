param workspaceName string = 'myWorkspaceName'
param location string = resourceGroup().location
param skuName string = 'PerGB2018'
param retentionInDays int =  30
param tags object

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
    features: {
      searchVersion:  1
      enableLogAccessUsingOnlyResourcePermissions: true
      immediatePurgeDataOn30Days: true
    }
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
