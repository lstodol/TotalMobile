param tags object
param environment string
param location string
param storageAccountName string
param identityName string
param mainStorageAccountName string
param tenantContainerName string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
  tags: tags
}

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
      defaultAction: 'Deny'
    }
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
  }

  dependsOn:[userAssignedIdentity]
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

// https://learn.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
var storageBlobDataContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
)
var storageBlobDataReaderRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
)

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(storageAccount.id, storageBlobDataContributorRoleId, userAssignedIdentity.name)
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal' 
    roleDefinitionId: storageBlobDataContributorRoleId
  }
}

resource mainStorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: mainStorageAccountName
}

resource tenantblobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' existing = {
  name: 'default'
  parent: mainStorageAccount
}

resource newTenantContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: tenantblobService
  name: tenantContainerName
}

resource storageReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope:  newTenantContainer
  name: guid(newTenantContainer.id, storageBlobDataReaderRoleId, userAssignedIdentity.name)
  properties: {
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal' 
    roleDefinitionId: storageBlobDataReaderRoleId 
  }
}
