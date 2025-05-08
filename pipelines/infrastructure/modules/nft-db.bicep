@description('The name of the SQL logical server.')
param serverName string = 'nft-analytics-u-uks-sql'

@description('The name of the SQL Database.')
param sqlDBName string = 'Carelink'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The administrator username of the SQL logical server.')
param administratorLogin string = 'sqladmin'

@secure()
@description('The administrator password of the SQL logical server.')
param administratorLoginPassword string 

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  parent: sqlServer
  name: sqlDBName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 10
  }
  properties: {
    autoPauseDelay: 60
    catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    createMode: 'Default'
    zoneRedundant: false
    requestedBackupStorageRedundancy: 'Local'
  }
}
