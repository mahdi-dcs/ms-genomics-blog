param keyVaultName string
@secure()
param secrets object

//-------------------------------------------------------------------
// Get references to existing resources
//-------------------------------------------------------------------
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}
//-------------------------------------------------------------------
// Create secrets
//-------------------------------------------------------------------
resource secretResources 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = [for secret in items(secrets): {
  name: secret.key
  parent: keyVault
  properties: {
    value: secret.value
  }
}]
