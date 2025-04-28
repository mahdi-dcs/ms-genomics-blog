@description('The target environment for the resources to be deployed.')
param targetEnv string

@description('The Azure region where the resources will be deployed.')
param location string

@description('The name of the Azure Batch account to be created.')
param batchAccountName string

@description('The name of the private link endpoint for the Batch account.')
param batchAccountPleName string

@description('The name of the private link endpoint for node management in the Batch account.')
param batchAccountNodeManagementPleName string

@description('A set of tags to be applied to all resources for consistent resource management.')
param defaultTags object

@description('The resource ID of the subnet where the Batch account will be deployed.')
param subnetId string

@description('Specifies whether public network access is enabled or disabled for the Batch account. Defaults to \'Disabled\'.')
param publicNetworkAccess string

@description('The resource ID of the subnet to be used for the private endpoint. Defaults to an empty string if not specified.')
param privateEndpointSubnetId string

@description('The resource ID of the storage account to be linked with the Batch account.')
param storageAccountId string

@description('The resource ID of the user-assigned managed identity to be used for the Batch account.')
param userManagedIdentityResourceId string

@description('The name of the Azure Container Registry account to be used for the Batch account.')
param acrAccountName string

@description('Node fill type for the Batch account. Defaults to \'Pack\'.')
param nodeFillType string = 'Pack'

@description('The number of task slots per node in the Batch account. Defaults to 4.')
param taskSlotsPerNode int = 4

@description('VM size for the VMs running the Nextflow pipeline.')
param pipelineVMSize string = 'STANDARD_D4_V5'

@description('VM size for the VMs running the Nextflow runner.')
param nfVMSize string = 'STANDARD_DC1s_V2'

@description('The name of the Batch pool for the Nextflow pipeline.')
param batchPoolName string = 'nf-pipeline-pool-${pipelineVMSize}-${targetEnv}'

@description('The name of the Batch pool for the Nextflow runner.')
param batchNFRunnerPoolName string = 'nf-runner-pool-${nfVMSize}-${targetEnv}'

var imageReference = {
  publisher: 'microsoft-dsvm'
  offer: 'ubuntu-hpc'
  sku: '2204'
  version: 'latest'
}
var nodeAgentSkuId = 'batch.node.ubuntu 22.04'
var containerConfiguration = {
  type: 'DockerCompatible'
  containerRegistries: [
    {
      identityReference: {
        resourceId: userManagedIdentityResourceId
      }
      password: privateContainerRegistry.listCredentials().passwords[0].value
      registryServer: privateContainerRegistry.properties.loginServer
      username: acrAccountName
    }
  ]
}

//https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.batch/batch-pool-no-public-ip/main.bicep#L87
resource batchAccount 'Microsoft.Batch/batchAccounts@2024-02-01' = {
  name: batchAccountName
  location: location
  tags: defaultTags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentityResourceId}': {}
    }
  }
  properties: {
    autoStorage: {
      storageAccountId: storageAccountId
      authenticationMode:'BatchAccountManagedIdentity'
      nodeIdentityReference:{
        resourceId:userManagedIdentityResourceId
      }
    }
    publicNetworkAccess: publicNetworkAccess
    allowedAuthenticationModes: [
      'SharedKey'
      'AAD'
      'TaskAuthenticationToken'
    ]
  }
}

resource batchPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = if (publicNetworkAccess == 'Disabled'){
  name: batchAccountPleName
  location: location
  tags: defaultTags
  properties: {
    privateLinkServiceConnections: [
      {
        name: batchAccountPleName
        properties: {
          groupIds: [
            'batchAccount'
          ]
          privateLinkServiceId: batchAccount.id
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetId
    }
  }
}

resource batchNodeManagementPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = if (publicNetworkAccess == 'Disabled'){
  name: batchAccountNodeManagementPleName
  location: location
  tags: defaultTags
  properties: {
    privateLinkServiceConnections: [
      {
        name: batchAccountNodeManagementPleName
        properties: {
          groupIds: [
            'nodeManagement'
          ]
          privateLinkServiceId: batchAccount.id
        }
      }
    ]
    subnet: {
      id: privateEndpointSubnetId
    }
  }
}

resource privateContainerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing =  {
  name: acrAccountName
}

// Create Pools

resource batchAccounts_pool_Standard_D4_v3 'Microsoft.Batch/batchAccounts/pools@2024-07-01' = {
  parent: batchAccount
  name: batchPoolName
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentityResourceId}': {}
    }
  }
  properties: {
    vmSize: pipelineVMSize
    interNodeCommunication: 'Disabled'
    targetNodeCommunicationMode: 'Simplified'
    taskSlotsPerNode: taskSlotsPerNode
    taskSchedulingPolicy: {
      nodeFillType: nodeFillType
    }
    deploymentConfiguration: {
      virtualMachineConfiguration: {
        imageReference: imageReference
        nodeAgentSkuId: nodeAgentSkuId
        containerConfiguration: containerConfiguration
        nodePlacementConfiguration: {
          policy: 'Regional'
        }
        osDisk:{
          caching: 'None'
          managedDisk:{
            storageAccountType: 'Standard_LRS'
          }
        }
      }
    }
    networkConfiguration: {
      subnetId: subnetId
      publicIPAddressConfiguration: {
        provision: 'NoPublicIPAddresses'
      }
      dynamicVnetAssignmentScope: 'none'
      enableAcceleratedNetworking: false
    }
    scaleSettings: {
      autoScale: {
        formula: '\n// Get pool lifetime since creation.\nlifespan = time() - time("2024-06-23T02:19:08.272769Z");\ninterval = TimeInterval_Minute * 5;\n\n// Compute the target nodes based on pending tasks.\n// $PendingTasks == The sum of $ActiveTasks and $RunningTasks\n$samples = $PendingTasks.GetSamplePercent(interval);\n$tasks = $samples < 70 ? max(0, $PendingTasks.GetSample(1)) : max( $PendingTasks.GetSample(1), avg($PendingTasks.GetSample(interval)));\n$targetVMs = $tasks > 0 ? $tasks : max(0, $TargetDedicatedNodes/2);\ntargetPoolSize = max(0, min($targetVMs, 5));\n\n// For first interval deploy 1 node, for other intervals scale up/down as per tasks.\n$TargetDedicatedNodes = lifespan < interval ? 1 : targetPoolSize;\n$NodeDeallocationOption = taskcompletion;\n'
        evaluationInterval: 'PT5M'
      }
    }
    startTask: {
      commandLine: 'bash -c "chmod +x azcopy && mkdir -p $AZ_BATCH_NODE_SHARED_DIR/bin/ && cp azcopy $AZ_BATCH_NODE_SHARED_DIR/bin/"'
      resourceFiles: [
        {
          filePath: 'azcopy'
          httpUrl: 'https://github.com/nextflow-io/azcopy-tool/raw/linux_amd64_10.8.0/azcopy'
        }
      ]
      userIdentity: {
        autoUser: {
          scope: 'Pool'
          elevationLevel: 'Admin'
        }
      }
      maxTaskRetryCount: 0
      waitForSuccess: true
    }
  }
  dependsOn: [
    batchNodeManagementPrivateEndpoint
  ]
} 

resource batchAccounts_pool_STANDARD_DC1s_V2 'Microsoft.Batch/batchAccounts/pools@2024-07-01' =  {
  parent: batchAccount
  name: batchNFRunnerPoolName
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentityResourceId}': {}
    }
  }
  properties: {
    vmSize: nfVMSize
    interNodeCommunication: 'Disabled'
    targetNodeCommunicationMode: 'Simplified'
    taskSlotsPerNode: taskSlotsPerNode
    taskSchedulingPolicy: {
      nodeFillType: nodeFillType
    }
    deploymentConfiguration: {
      virtualMachineConfiguration: {
        imageReference: imageReference
        nodeAgentSkuId: nodeAgentSkuId
        containerConfiguration: containerConfiguration
        nodePlacementConfiguration: {
          policy: 'Regional'
        }
        osDisk:{
          caching: 'None'
          managedDisk:{
            storageAccountType: 'Standard_LRS'
          }
        }
      }
    }
    networkConfiguration: {
      subnetId: subnetId
      publicIPAddressConfiguration: {
        provision: 'NoPublicIPAddresses'
      }
      dynamicVnetAssignmentScope: 'none'
      enableAcceleratedNetworking: false
    }
    scaleSettings: {
      autoScale: {
        formula: '\n// Get pool lifetime since creation.\nlifespan = time() - time("2024-06-23T02:19:08.272769Z");\ninterval = TimeInterval_Minute * 5;\n\n// Compute the target nodes based on pending tasks.\n// $PendingTasks == The sum of $ActiveTasks and $RunningTasks\n$samples = $PendingTasks.GetSamplePercent(interval);\n$tasks = $samples < 70 ? max(0, $PendingTasks.GetSample(1)) : max( $PendingTasks.GetSample(1), avg($PendingTasks.GetSample(interval)));\n$targetVMs = $tasks > 0 ? $tasks : max(0, $TargetDedicatedNodes/2);\ntargetPoolSize = max(0, min($targetVMs, 5));\n\n// For first interval deploy 1 node, for other intervals scale up/down as per tasks.\n$TargetDedicatedNodes = lifespan < interval ? 1 : targetPoolSize;\n$NodeDeallocationOption = taskcompletion;\n'
        evaluationInterval: 'PT5M'
      }
    }
    startTask: {
      commandLine: 'bash -c "chmod +x azcopy && mkdir -p $AZ_BATCH_NODE_SHARED_DIR/bin/ && cp azcopy $AZ_BATCH_NODE_SHARED_DIR/bin/"'
      resourceFiles: [
        {
          filePath: 'azcopy'
          httpUrl: 'https://github.com/nextflow-io/azcopy-tool/raw/linux_amd64_10.8.0/azcopy'
        }
      ]
      userIdentity: {
        autoUser: {
          scope: 'Pool'
          elevationLevel: 'Admin'
        }
      }
      maxTaskRetryCount: 0
      waitForSuccess: true
    }
  }
  dependsOn: [
    batchNodeManagementPrivateEndpoint
  ]
} 


output batchPoolId string = batchAccounts_pool_Standard_D4_v3.id
output batchPoolName string = batchPoolName
output batchAccountId string = batchAccount.id
