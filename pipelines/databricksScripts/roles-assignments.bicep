param dataFactoryPrincipalId string
param appServicePrincipalId string
param storageAccountName string

// https://learn.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, storageBlobDataContributorRoleId)
  properties: {
    principalId: dataFactoryPrincipalId
    roleDefinitionId: storageBlobDataContributorRoleId
  }
  scope: storageAccount
}

resource storageRoleAssignmentAppServicePrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, storageBlobDataContributorRoleId, appServicePrincipalId)
  properties: {
    principalId: appServicePrincipalId
    roleDefinitionId: storageBlobDataContributorRoleId
  }
  scope: storageAccount
}
