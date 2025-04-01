param keyVaultName string
param principalId string
@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'
@allowed([
  'Administrator'
  'Reader'
  'CertificatesOfficer'
  'CertificateUser'
  'CryptoOfficer'
  'CryptoServiceEncryptionUser'
  'CryptoUser'
  'SecretsOfficer'
  'SecretsUser'
  'DataAccessAdministrator'
])
param role string = 'SecretsUser'

// Key Vault roles. See: https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide?tabs=azure-cli
var roleDefinitions = {
  Administrator: {
    id: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
    description: 'Key Vault Administrator'
  }
  Reader: {
    id: '21090545-7ca7-4776-b22c-e363652d74d2'
    description: 'Key Vault Reader'
  }
  CertificatesOfficer: {
    id: 'a4417e6f-fecd-4de8-b567-7b0420556985'
    description: 'Key Vault Certificates Officer'
  }
  CertificateUser: {
    id: 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba'
    description: 'Key Vault Certificate User'
  }
  CryptoOfficer: {
    id: '14b46e9e-c2b7-41b4-b07b-48a6ebf60603'
    description: 'Key Vault Crypto Officer'
  }
  CryptoServiceEncryptionUser: {
    id: 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
    description: 'Key Vault Crypto Service Encryption User'
  }
  CryptoUser: {
    id: '12338af0-0e69-4776-bea7-57ae8d297424'
    description: 'Key Vault Crypto User'
  }
  SecretsOfficer: {
    id: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
    description: 'Key Vault Secrets Officer'
  }
  SecretsUser: {
    id: '4633458b-17de-408a-b874-0445c86b69e6'
    description: 'Key Vault Secrets User'
  }
  DataAccessAdministrator: {
    id: '8b54135c-b56d-4d72-a534-26097cfdc8d8'
    description: 'Key Vault Data Access Administrator'
  }
}

// get references to Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultName, principalId, resourceGroup().id, roleDefinitions[role].id)
  scope: keyVault
  properties: {
    description: roleDefinitions[role].description
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitions[role].id)
    principalType: principalType
  }
}
