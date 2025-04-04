param vnetName string = 'genom-dev-vnet'
param subnetName string = 'default'
param privateEndpointsSubnetName string = 'private-endpoints'
param targetEnv string = 'dev'
param location string = 'canadacentral'
param vnetResourceGroup string = 'genom-dev-rg'
param solutionName string = 'genomics'
param keyVaultSku string = 'Standard'

param deploymentName string = deployment().name

var defaultTags = {
  environment: targetEnv
}

var storageAccountName = '${targetEnv}sa${solutionName}01'
var batchAccountName = '${targetEnv}batch${solutionName}01'
var batchStorageAccountName = '${targetEnv}bsa${solutionName}01'
var kvName = '${solutionName}kv${targetEnv}01'
var containerRegistryName = '${solutionName}acr${targetEnv}01'
var acrPasswordSecretName = 'acr-password-${targetEnv}'
var batchUserManagedIdentityName = '${targetEnv}batch-umi${solutionName}01'

// Import vnet and subnets: this template assumes that the vnet and subnets are already created as part of the Enterprise Landing Zone.
resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: subnetName
  parent: vnet
}

resource privateEndpointsSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: privateEndpointsSubnetName
  parent: vnet
}

// Nextflow Storage Account
module storage 'modules/storage/main.bicep' = {
  name: '${deploymentName}-storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    defaultTags: defaultTags
    publicNetworkAccess: 'Disabled'
    blobContainerNames: [
      'nextflow'
    ]
    privateEndpointSubnetId:privateEndpointsSubnet.id
  }
}


// Batch Account and its Managed Identity and Storage Account
module batchStorage 'modules/storage/main.bicep' = {
  name: '${deploymentName}-batch-storage'
  params: {
    storageAccountName: batchStorageAccountName
    location: location
    defaultTags: defaultTags
    publicNetworkAccess: 'Disabled'
    blobContainerNames: [
      'nextflow'
    ]
    privateEndpointSubnetId:privateEndpointsSubnet.id
    isHnsEnabled: false // this is needed to be able to have version control on the pipeline references.
  }
}

resource batchUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: batchUserManagedIdentityName
  location: location
}

module batchAccountModule 'modules/batch/main.bicep' = {
  name: '${deploymentName}-batchsa'
  params: {
    batchAccountName: batchAccountName
    location: location
    defaultTags: defaultTags
    subnetId: subnet.id
    storageAccountId:batchStorage.outputs.storageAccountId
    publicNetworkAccess: 'Disabled'
    userManagedIdentityResourceId: batchUserManagedIdentity.id
    targetEnv: targetEnv
    privateEndpointSubnetId: privateEndpointsSubnet.id
    acrAccountName: containerRegistryName
    batchAccountPleName: '${batchAccountName}-ple'
    batchAccountNodeManagementPleName: '${batchAccountName}-node-management-ple'
  }
}

// Key Vault
module keyVaultModule './modules/key-vault/main.bicep' = {
  name: '${deploymentName}-kv'
  params: {
    location: location
    keyVaultName: kvName
    keyVaultSku: keyVaultSku
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    keyvaultPleName: '${kvName}-ple'
    publicNetworkAccess: 'Disabled'
    subnetId:privateEndpointsSubnet.id
    ipRules: null
    virtualNetworkRules: null
  }
}
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
}

resource acrPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = {
  name: acrPasswordSecretName
  parent: keyVault
  properties: {
    value: acrResource.listCredentials().passwords[0].value
  }
  dependsOn: [
    acrPrivateEndpoint
  ]
}

// Azure Container Registry
resource acrResource 'Microsoft.ContainerRegistry/registries@2023-07-01' =  {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true
    dataEndpointEnabled:false
    networkRuleBypassOptions:'AzureServices'
    networkRuleSet: {
      defaultAction: 'Deny'
    }
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
      trustPolicy: {
        status: 'disabled'
        type: 'Notary'
      }
    }
    publicNetworkAccess: 'Disabled'
    zoneRedundancy: 'Disabled'
  }
}

resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${containerRegistryName}-ple'
  location: location
  tags: defaultTags
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${containerRegistryName}-ple'
        properties: {
          groupIds: [
            'registry'
          ]
          privateLinkServiceId: acrResource.id
        }
      }
    ]
    subnet: {
      id: privateEndpointsSubnet.id
    }
  }
}

// Role assignments for Batch User Managed Identity
module acrRoleAssignment 'modules/roles/main.bicep' = {
  name: '${deploymentName}-acr-role'
  params: {
    acrName: acrResource.name
    storageAccountName: storageAccountName
    batchStorageAccountName: batchStorageAccountName
    keyVaultName: kvName
    principalId: batchUserManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource batchAccount 'Microsoft.Batch/batchAccounts@2024-02-01' existing = {
  name: batchAccountName
  dependsOn: [
    batchAccountModule
  ]
}

resource secretResourcesBatchKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'batch-account-key'
  parent: keyVault
  properties: {
    value: batchAccount.listKeys().primary
  }
  dependsOn: [
    batchAccount
  ]
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
  dependsOn: [
    storage
  ]
}

resource secretResourcesStorageKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'storage-account-key'
  parent: keyVault
  properties: {
    value: storageAccount.listKeys().keys[0].value
  }
  dependsOn: [
    storageAccount
  ]
}
