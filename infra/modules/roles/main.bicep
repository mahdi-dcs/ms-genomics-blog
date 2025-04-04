@description('The ID of the principal (user, group, service principal) to assign the role to')
param principalId string

@description('The type of principal (User, Group, ServicePrincipal)')
@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'

param storageAccountName string

param keyVaultName string

param batchStorageAccountName string

param acrName string

// Role definitions mapping
var roleDefinitions = {
  StorageBlobDataContributor: {
    resourceType: 'Microsoft.Storage/storageAccounts'
    id: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    description: 'Read, write, and delete Azure Storage containers and blobs.'
  }
  KeyVaultSecretUser: {
    resourceType: 'Microsoft.KeyVault/vaults'
    id: '4633458b-17de-408a-b874-0445c86b69e6'
    description: 'Read secret contents.'
  }
  AcrPull: {
    resourceType: 'Microsoft.ContainerRegistry/registries'
    id: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    description: 'built-in AcrPull role.'
  }
  StorageBlobDataReader: {
    resourceType: 'Microsoft.Storage/storageAccounts'
    id: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    description: 'Read and list Azure Storage containers and blobs.'
  }
  KeyVaultSecretReader: {
    resourceType: 'Microsoft.KeyVault/vaults'
    id: '21090545-7ca7-4776-b22c-e363652d74d2'
    description: 'Read key vault secrets.'
  }
  ContributorRole: {
    id: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
    description: 'Read, write, and delete Azure Storage containers and blobs.'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: keyVaultName
}
resource batchStorageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: batchStorageAccountName
}
resource acrResource 'Microsoft.ContainerRegistry/registries@2024-11-01-preview' existing = {
  name: acrName
}

// ACR Role Assignments
resource managedIdentityRoleAssignmentACRPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, acrResource.id, roleDefinitions.AcrPull.id)
  scope: acrResource
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.AcrPull.id)
    principalId: principalId
    principalType: principalType
  }
}

// Key Vault Role Assignments
resource managedIdentityRoleAssignmentKeyVaultUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyVault.id, roleDefinitions.KeyVaultSecretUser.id)
  scope: keyVault
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.KeyVaultSecretUser.id)
    principalId: principalId
    principalType: principalType
  }
}

resource managedIdentityRoleAssignmentKeyVaultReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyVault.id, roleDefinitions.KeyVaultSecretReader.id)
  scope: keyVault
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.KeyVaultSecretReader.id)
    principalId: principalId
    principalType: principalType
  }
}

// Storage Account Role Assignments
resource managedIdentityRoleAssignmentStorageAccountBlobContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, storageAccount.id, roleDefinitions.StorageBlobDataContributor.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.StorageBlobDataContributor.id)
    principalId: principalId
    principalType: principalType
  }
}

resource managedIdentityRoleAssignmentStorageAccountBlobReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, storageAccount.id, roleDefinitions.StorageBlobDataReader.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.StorageBlobDataReader.id)
    principalId: principalId
    principalType: principalType
  }
}

// Batch Storage Account Role Assignments
resource managedIdentityRoleAssignmentBatchStorageAccountBlobContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, batchStorageAccount.id, roleDefinitions.StorageBlobDataContributor.id)
  scope: batchStorageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.StorageBlobDataContributor.id)
    principalId: principalId
    principalType: principalType
  }
}

resource managedIdentityRoleAssignmentBatchStorageAccountBlobReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, batchStorageAccount.id, roleDefinitions.StorageBlobDataReader.id)
  scope: batchStorageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.StorageBlobDataReader.id)
    principalId: principalId
    principalType: principalType
  }
}

resource managedIdentityRoleAssignmentBatchStorageAccountContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, batchStorageAccount.id, roleDefinitions.ContributorRole.id)
  scope: batchStorageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions.ContributorRole.id)
    principalId: principalId
    principalType: principalType
  }
}

