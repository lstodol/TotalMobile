param dataFactoryName string
param location string
param tags object
param environment string
param codeRepositoryName string
param accountName string = 'totalmobile'
param collaborationBranch string = 'main'
param rootFolder string = '/azureDataFactory'
param logAnalyticsWorkspaceId string
param userAssignedIdentities object = {}

var gitHubRepoConfiguration = {
  accountName: accountName
  repositoryName: codeRepositoryName
  collaborationBranch: collaborationBranch
  rootFolder: rootFolder
  type: 'FactoryGitHubConfiguration'
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  tags: tags
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: userAssignedIdentities
  }
  properties: {
    repoConfiguration: (environment == 'dev') ? gitHubRepoConfiguration : {}
  }
}

// Create diagnostic settings for the Data Factory to send logs to Log Analytics
resource adfDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${dataFactoryName}-diagnostic-settings'
  scope: dataFactory
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
    logAnalyticsDestinationType: 'Dedicated'
  }
}

output adfResourceId string = dataFactory.id
output dataFactoryPrincipalId string = dataFactory.identity.principalId
