using 'main.bicep'

param yourName = 'henri'
param ownerEmail = 'fheau002@edu.xamk.fi'
param environment = 'dev'
param location = 'swedencentral'
param postgresAdminPassword = readEnvironmentVariable('POSTGRES_ADMIN_PASSWORD')
