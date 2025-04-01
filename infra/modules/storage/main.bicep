@description('The name of the storage account')
param storageAccountName string

@description('The location of the storage account')
param location string

@description('The default tags for the resources')
param defaultTags object

@description('The ID of the private endpoint subnet')
param privateEndpointSubnetId string = ''

@description('The names of the blob containers')
param virtualNetworkRules array = []

@description('The resource access rules for the storage account')
param resourceAccessRules array = []

@description('The public network access setting for the storage account: Enabled or Disabled')
param publicNetworkAccess string = 'Enabled'

@description('The names of the blob containers to be created')
param blobContainerNames array = []

@description('Whether to enable Hierarchical Namespace for the storage account')
param isHnsEnabled bool = true

@description('default access tier for the storage account')
param accessTier string = 'Hot'

@description('Storage account type')
param storageAccountType string = 'StorageV2'

@description('Whether to enable HTTPS traffic only for the storage account')
param supportsHttpsTrafficOnly bool = true

@description('Whether to allow public access to blobs')
param allowBlobPublicAccess bool = false

@description('The minimum TLS version for the storage account')
param minimumTlsVersion string = 'TLS1_2'

@description('The name of the storage account SKU')
param skuName string = 'Standard_LRS'

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: skuName
  }
  kind: storageAccountType
  tags: defaultTags
  properties: {
    accessTier: accessTier
    isHnsEnabled: isHnsEnabled
    supportsHttpsTrafficOnly: supportsHttpsTrafficOnly
    allowBlobPublicAccess: allowBlobPublicAccess
    minimumTlsVersion: minimumTlsVersion
    publicNetworkAccess:publicNetworkAccess  
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: virtualNetworkRules
      resourceAccessRules: resourceAccessRules
    }
  }
}


// Blob Containers
resource blobContainerService 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' = {
  name:'default'
  parent: storageAccount
}

resource BlobContainers 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = [for blobContainerName in blobContainerNames: {
  parent: blobContainerService
  name: blobContainerName
}]

var storageEndpoint = 'https://${storageAccount.name}.blob.${environment().suffixes.storage}'

// Private endpoint for blob service
resource sablobpe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${storageAccountName}-blobpe'
  location: location
  properties:{
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
    {
      name: '${storageAccountName}-blobpe-conn'
      properties: {
        privateLinkServiceId: storageAccount.id
        groupIds:[
          'blob'
        ]
        privateLinkServiceConnectionState: {
          status: 'Approved'
          actionsRequired: 'None'
        }
      }
    }
    ]
  }
}

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output storageBlobServiceEndpoint string = storageEndpoint
output storageAccountResource object = storageAccount
