param planName string
param appName string
param location string = resourceGroup().location
param storageAccountName string
param deploymentStorageContainerName string
param applicationInsightsName string
param tags object = {}
param serviceName string
param functionAppRuntime string = 'dotnet-isolated'
param functionAppRuntimeVersion string = '9.0'
param maximumInstanceCount int = 100
param instanceMemoryMB int = 2048

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource flexPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: planName
  location: location
  tags: union(tags, { 'azd-service-name': serviceName })
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

resource flexApp 'Microsoft.Web/sites@2024-04-01' = {
  name: appName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: flexPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storage.name
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
      ]
    }
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storage.properties.primaryEndpoints.blob}${deploymentStorageContainerName}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: maximumInstanceCount
        instanceMemoryMB: instanceMemoryMB
      }
      runtime: {
        name: functionAppRuntime
        version: functionAppRuntimeVersion
      }
    }
  }
}

// @description('This is the built-in role definition for the Azure Storage Blob Data Owner role. See https://learn.microsoft.com/azure/role-based-access-control/built-in-roles#storage-blob-data-owner for more information.')
// resource storageBlobDataOwnerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
//   scope: subscription()
//   name: 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b'
// }

// // TODO: Scope to the specific resource (Event Hub, Storage, Key Vault) instead of the resource group.
// //       See https://github.com/Azure/bicep/discussions/5926
// module storageRoleAssignment '../security/role.bicep' = {
//   name: 'storageRoleAssignment'
//   params: {
//     principalId: flexApp.identity.principalId
//     roleDefinitionId: storageBlobDataOwnerRoleDefinition.name
//     principalType: 'ServicePrincipal'
//   }
// }

output name string = flexApp.name
output identityPrincipalId string = flexApp.identity.principalId
