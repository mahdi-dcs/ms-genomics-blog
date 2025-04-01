param location string = resourceGroup().location
param keyVaultName string
param enabledForDeployment bool = false
param enabledForDiskEncryption bool = false
param enabledForTemplateDeployment bool = false
param ipRules array = []
param virtualNetworkRules array = []
param keyVaultSku string = 'Standard'

@description('The Subnet ID where the Key Vault Private Link is to be created')
param subnetId string = ''

@description('The name of the Key Vault private link endpoint')
param keyvaultPleName string = ''

@description('Defining if public network access is needed.')
param publicNetworkAccess string = 'disabled'

@description('Retention period for deleted keyvalut')
param softDeleteRetentionInDays int = 90

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: keyVaultSku
    }
    enableRbacAuthorization: true
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    enablePurgeProtection:true
    enableSoftDelete:true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    publicNetworkAccess:publicNetworkAccess
    networkAcls: publicNetworkAccess == 'disabled' ? {
      bypass: 'AzureServices'
      defaultAction:'Deny'
      ipRules: ipRules
      virtualNetworkRules:virtualNetworkRules
    } : null
  }
}


resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: keyvaultPleName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: keyvaultPleName
        properties: {
          groupIds: [
            'vault'
          ]
          privateLinkServiceId: keyVault.id
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}

output id string = keyVault.id
output name string = keyVault.name

