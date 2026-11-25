param yourName string
param ownerEmail string
param location string = resourceGroup().location

@secure()
param postgresAdminPassword string

var environment = 'dev'
var planName = 'plan-cloud26-${yourName}-${environment}'
var appName = 'app-cloud26-${yourName}-${environment}'
var postgresName = 'pg-cloud26-${yourName}-${environment}'
var databaseName = 'campusevents'
var postgresAdminLogin = 'campusadmin'

var tags = {
  Environment: environment
  Course: 'cloud26'
  Owner: ownerEmail
  ManagedBy: 'Bicep'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  properties: {
    reserved: true
  }
  tags: tags
}

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: postgresName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    version: '16'
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    authConfig: {
      passwordAuth: 'Enabled'
      activeDirectoryAuth: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
  tags: tags
}

resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgresServer
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

resource allowAzureServices 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: postgresServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: appName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|10.0'
      alwaysOn: false
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'ConnectionStrings__DefaultConnection'
          value: 'Host=${postgresServer.properties.fullyQualifiedDomainName};Database=${databaseName};Username=${postgresAdminLogin};Password=${postgresAdminPassword};Ssl Mode=Require'
        }
      ]
    }
  }
  tags: tags
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output postgresServerFqdn string = postgresServer.properties.fullyQualifiedDomainName
