targetScope = 'subscription'

param servicePrincipalId string
param accessPolicies array
param servicePrincipalKey string
param codeRepositoryName string
param environment string
param location string
param tenantId string = subscription().tenantId
param domain string
param project string
param tags object
param emailReceivers array
param hotPathEntities array
param createdDate string = utcNow('yyyy-MM-dd')
param appServicePrincipalId string
param dataSharing array
@secure()
param awsGatewaySharedKey string
@secure()
param encodedProductteamWarehouseConnectionProps string
param analyticsAdapterPrimarySubnetId string
param analyticsAdapterSecondarySubnetId string


var regionLookup = loadJsonContent('./global/regions.json')
var locationPart = regionLookup[location].code

var resourceGroupName = toLower('${environment}-${domain}-${project}-${locationPart}-rg')
var keyVaultName = toLower('${environment}-${domain}-${project}-${locationPart}-kv')
var storageAccountName = toLower('${environment}${domain}${project}${locationPart}st')
var dbxWorkspaceName = toLower('${environment}-${domain}-${project}-${locationPart}-dbx')
var dataFactoryName = toLower('${environment}-${domain}-${project}-${locationPart}-df')
var networkSecurityGroupName = toLower('${environment}-${domain}-${project}-${locationPart}-nsg')
var vnetName = toLower('${environment}-${domain}-${project}-${locationPart}-vnet')
var hostSubnetName = toLower('${environment}-${domain}-${project}-${locationPart}-sub-host')
var containerSubnetName = toLower('${environment}-${domain}-${project}-${locationPart}-sub-container')
var logAnalyticsWorkspaceName = toLower('${environment}-${domain}-${project}-${locationPart}-law')
var actionGroupName = toLower('${environment}-${domain}-${project}-${locationPart}-action-group')
var alertRuleNamePipelineFailedRuns = toLower('${environment}-${domain}-${project}-${locationPart}-adf-pipeline-failure-alert')
var alertRuleNamePipelineRunDuration = toLower('${environment}-${domain}-${project}-${locationPart}-adf-pipeline-run-duration-alert')
var alertRuleNamePipelineRunDuration30m = toLower('${environment}-${domain}-${project}-${locationPart}-adf-pipeline-run-duration-alert-30m')
var alertRuleNamePipelineRunDuration1h = toLower('${environment}-${domain}-${project}-${locationPart}-adf-pipeline-run-duration-alert-1h')
var alertRuleNamePipelineRunDuration2h = toLower('${environment}-${domain}-${project}-${locationPart}-adf-pipeline-run-duration-alert-2h')
var alertRuleNamePipelineRunDuration4h = toLower('${environment}-${domain}-${project}-${locationPart}-adf-pipeline-run-duration-alert-4h')
var alertRuleNamePipelineRunDuration8h = toLower('${environment}-${domain}-${project}-${locationPart}-adf-pipeline-run-duration-alert-8h')
var alertRuleNamePipelineRunDuration12h = toLower('${environment}-${domain}-${project}-${locationPart}-adf-pipeline-run-duration-alert-12h')
var alertRuleNamePipelineRunDuration24h = toLower('${environment}-${domain}-${project}-${locationPart}-adf-pipeline-run-duration-alert-24h')
var alertServiceHealthName = toLower('${environment}-${domain}-${project}-${locationPart}-azure-service-health-alert')
var eventHubNamespaceName = toLower('${environment}-${domain}-${project}-${locationPart}-evhns')
var vNetGatewayName = (environment == 'dev') ? 'unity-data-dev-vng' : toLower('${environment}-${domain}-${project}-${locationPart}-vng')
var gatewaySubnetName = 'GatewaySubnet'

var includeAWSResources = environment == 'dev' || environment == 'nft'

var addedTags = {
  CreatedDate: createdDate
  CreatedBy: servicePrincipalId
}
var extendedTags = union(tags, addedTags)


resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: extendedTags
}

module networks 'modules/networks.bicep' = {
  name: 'Networks'
  scope: rg
  params: {
    location: location
    vnetName: vnetName
    networkSecurityGroupName: networkSecurityGroupName
    containerSubnetName: containerSubnetName
    vNetGatewayName: vNetGatewayName
    hostSubnetName: hostSubnetName
    awsGatewaySharedKey: awsGatewaySharedKey
    gatewaySubnetName: gatewaySubnetName
    includeAWSResources: includeAWSResources
  }
}

module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'LogAnalytics'
  scope: rg
  params: {
    location: location
    retentionInDays: 30
    workspaceName: logAnalyticsWorkspaceName
    tags: extendedTags
  }
}

module storageAccount 'modules/storage-account.bicep' = {
  name: 'BlobStorage'
  scope: rg
  params: {
    location: location
    environment: environment
    storageAccountName: storageAccountName
    tags: extendedTags
    containerSubnetId: networks.outputs.containerSubnetId
    hostSubnetId: networks.outputs.hostSubnetId
  }
}

module dbxWorkspace 'modules/dbx-workspace.bicep' = {
  name: 'DbxWorkspace'
  scope: rg
  params: {
    location: location
    dbxWorkspaceName: dbxWorkspaceName
    vnetId: networks.outputs.vnetId
    hostSubnetName: hostSubnetName
    tags: extendedTags
    containerSubnetName: containerSubnetName
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
  }
}

module storageAccountDatasharing 'modules/storage-account-datasharing.bicep' = [
  for item in dataSharing: {
    name: '${item.storageAccount}BlobStorage'
    scope: rg
    params: {
      location: location
      environment: environment
      storageAccountName: item.storageAccount
      identityName: item.identity
      tags: extendedTags
      mainStorageAccountName: storageAccountName
      tenantContainerName: item.tenantName
    }
  }
]

var identities = [
  for item in dataSharing: {
    id: resourceId(subscription().subscriptionId, rg.name, 'Microsoft.ManagedIdentity/userAssignedIdentities', item.Identity)
    value: {}
  }
]
var identitiesObject = toObject(identities, item => '${item.id}', item => item.value)

module dataFactory 'modules/data-factory.bicep' = {
  name: 'DataFactory'
  scope: rg
  params: {
    location: location
    tags: extendedTags
    environment: environment
    dataFactoryName: dataFactoryName
    codeRepositoryName: codeRepositoryName
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    userAssignedIdentities: identitiesObject
  }
  dependsOn: storageAccountDatasharing
}


module rolesAssignments 'modules/roles-assignments.bicep' = {
  name: 'RolesAssignments'
  scope: rg
  params: {
    dataFactoryPrincipalId: dataFactory.outputs.dataFactoryPrincipalId
    appServicePrincipalId: appServicePrincipalId
    storageAccountName: storageAccountName
  }
}

var extendedAccessPolicies = concat(accessPolicies, [
  {
    objectId: dataFactory.outputs.dataFactoryPrincipalId
    permissions: {
      secrets: ['Get', 'List']
    }
  }
])

module keyVault 'modules/key-vault.bicep' = {
  name: 'KeyVault'
  scope: rg
  params: {
    location: location
    tenantId: tenantId
    keyVaultName: keyVaultName
    accessPolicies: extendedAccessPolicies
    hostSubnetId: networks.outputs.hostSubnetId
    tags: extendedTags
  }
}

module eventHubNameSpace 'modules/event-hub.bicep' = {
  name: 'EventHubNameSpace'
  dependsOn: [keyVault]
  scope: rg
  params: {
    eventHubNameSpace: eventHubNamespaceName
    location: location
    tags: extendedTags
    hostSubnetId: networks.outputs.hostSubnetId
    containerSubnetId: networks.outputs.containerSubnetId
    hotPathEntities: hotPathEntities
    keyVaultName: keyVaultName
    analyticsAdapterPrimarySubnetId: analyticsAdapterPrimarySubnetId
    analyticsAdapterSecondarySubnetId: analyticsAdapterSecondarySubnetId
  } 
}

module metricAlerts 'modules/metric-alerts.bicep' = {
  name: 'Metrics'
  scope: rg
  params: {
    location: 'Global'
    alertRuleNamePipelineFailedRuns: alertRuleNamePipelineFailedRuns
    alertRuleNamePipelineRunDuration: alertRuleNamePipelineRunDuration
    alertRuleNamePipelineRunDuration30m: alertRuleNamePipelineRunDuration30m
    alertRuleNamePipelineRunDuration1h: alertRuleNamePipelineRunDuration1h
    alertRuleNamePipelineRunDuration2h: alertRuleNamePipelineRunDuration2h
    alertRuleNamePipelineRunDuration4h: alertRuleNamePipelineRunDuration4h
    alertRuleNamePipelineRunDuration8h: alertRuleNamePipelineRunDuration8h
    alertRuleNamePipelineRunDuration12h: alertRuleNamePipelineRunDuration12h
    alertRuleNamePipelineRunDuration24h: alertRuleNamePipelineRunDuration24h
    alertServiceHealthName: alertServiceHealthName
    regionToMonitor: regionLookup[location].displayname
    actionGroupName: actionGroupName
    dataFactoryResourceId: dataFactory.outputs.adfResourceId
    emailReceivers: emailReceivers
    environment: environment
  }
}

var dataSharingStoragesArray = map(dataSharing, item => item.storageAccount)
var dataSharingStorages = join(dataSharingStoragesArray, ',')

module secrets 'modules/secrets.bicep' = {
  name: 'vaultSecrets'
  scope: rg
  dependsOn: [ keyVault, dbxWorkspace, eventHubNameSpace ]
  params: {
    keyVaultName: keyVaultName
    keyVaultId: keyVault.outputs.keyVaultId
    tenantId: tenantId
    keyVaultUri: keyVault.outputs.keyVaultUri
    dbxWorkspaceId: dbxWorkspace.outputs.databricksWorkspaceId
    dbxWorkspaceUrl: dbxWorkspace.outputs.databricksWorkspaceUrl
    saName: storageAccountName
    rgName: resourceGroupName
    servicePrincipalId: servicePrincipalId
    servicePrincipalKey: servicePrincipalKey
    networkSecurityGroupName: networkSecurityGroupName
    dataSharingStorages: dataSharingStorages
    eventHubNamespaceName: eventHubNamespaceName
    awsGatewaySharedKey: awsGatewaySharedKey
    encodedProductteamWarehouseConnectionProps: encodedProductteamWarehouseConnectionProps
    includeAWSResources: includeAWSResources
  }
}
