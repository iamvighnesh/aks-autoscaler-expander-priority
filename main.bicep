param clusterIdentityName string= 'uai-eus-aksautoscaler-priority'
param clusterIdentityLocation string= 'eastus'
param logAnalyticsWorkspaceName string= 'law-eus-aksautoscaler-priority'
param logAnalyticsWorkspaceLocation string= 'eastus'
param vnetName string= 'vnet-eus-aksautoscaler-priority'
param vnetLocation string= 'eastus'
param vnetAddressSpace string= '10.100.0.0/16'
param clusterName string= 'aks-eus-aksautoscaler-priority'
param clusterLocation string= 'eastus'
param aksAadAdminGroupId string

resource clusterIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: clusterIdentityName
  location: clusterIdentityLocation
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: logAnalyticsWorkspaceLocation
  properties: {
     sku: {
      name: 'PerGB2018'
     }
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnetName
  location: vnetLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: 'aks-nodepools'
        properties: {
          addressPrefix: '10.100.0.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'aks-pods-kubesystem'
        properties: {
          addressPrefix: '10.100.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'Microsoft.ContainerService.managedClusters'
              properties: {
                serviceName: 'Microsoft.ContainerService/managedClusters'
              }
            }
          ]
        }
      }
      {
        name: 'aks-pods-amdd8asv5'
        properties: {
          addressPrefix: '10.100.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'Microsoft.ContainerService.managedClusters'
              properties: {
                serviceName: 'Microsoft.ContainerService/managedClusters'
              }
            }
          ]
        }
      }
      {
        name: 'aks-pods-amdd32asv5'
        properties: {
          addressPrefix: '10.100.3.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'Microsoft.ContainerService.managedClusters'
              properties: {
                serviceName: 'Microsoft.ContainerService/managedClusters'
              }
            }
          ]
        }
      }
      {
        name: 'aks-pods-inteld8sv5'
        properties: {
          addressPrefix: '10.100.4.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'Microsoft.ContainerService.managedClusters'
              properties: {
                serviceName: 'Microsoft.ContainerService/managedClusters'
              }
            }
          ]
        }
      }
    ]
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-11-02-preview' = {
  name: clusterName
  location: clusterLocation
  sku: {
    name: 'Basic'
    tier: 'Paid'
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${clusterIdentity.id}': {}
    }
  }
  properties: {
    dnsPrefix: clusterName
    enableRBAC: true
    aadProfile: {
      enableAzureRBAC: true
      managed: true
      adminGroupObjectIDs: [
        aksAadAdminGroupId
      ]
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }
      azurepolicy: {
        enabled: true
      }
    }
    autoScalerProfile: {
      expander: 'priority'
      'scan-interval': '60s'
      'scale-down-unneeded-time': '3m'
    }
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
    }
    networkProfile: {
      networkPlugin: 'azure'
    }
    storageProfile: {
      diskCSIDriver: {
        enabled: true
      }
    }
    securityProfile: {
      imageCleaner: {
        enabled: true
        intervalHours: 24
      }
    }
    workloadAutoScalerProfile: {
      keda: {
        enabled: true
      }
    }
    agentPoolProfiles: [
      {
        name: 'kubesystem'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_D4as_v5'
        count: 3
        scaleDownMode: 'Deallocate'
        availabilityZones: [
          '1'
          '2'
          '3'
        ]
        osType: 'Linux'
        osSKU: 'Mariner'
        vnetSubnetID: vnet.properties.subnets[0].id
        podSubnetID: vnet.properties.subnets[1].id
      }
      {
        name: 'amdd8asv5'
        mode: 'User'
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_D8as_v5'
        count: 1
        minCount: 1
        maxCount: 10
        enableAutoScaling: true
        scaleSetPriority: 'Spot'
        scaleSetEvictionPolicy: 'Deallocate'
        scaleDownMode: 'Deallocate'
        spotMaxPrice: -1
        availabilityZones: [
          '1'
        ]
        osType: 'Linux'
        osSKU: 'Mariner'
        vnetSubnetID: vnet.properties.subnets[0].id
        podSubnetID: vnet.properties.subnets[2].id
        nodeLabels: {
          hardware: 'amd'
        }
      }
      {
        name: 'amdd32asv5'
        mode: 'User'
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_D32as_v5'
        count: 1
        minCount: 1
        maxCount: 10
        enableAutoScaling: true
        scaleSetPriority: 'Spot'
        scaleSetEvictionPolicy: 'Deallocate'
        scaleDownMode: 'Deallocate'
        spotMaxPrice: -1
        availabilityZones: [
          '2'
        ]
        osType: 'Linux'
        osSKU: 'Mariner'
        vnetSubnetID: vnet.properties.subnets[0].id
        podSubnetID: vnet.properties.subnets[2].id
        nodeLabels: {
          hardware: 'amd'
        }
      }
      {
        name: 'inteld8sv5'
        mode: 'User'
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_D8s_v5'
        count: 1
        minCount: 1
        maxCount: 10
        enableAutoScaling: true
        scaleSetPriority: 'Spot'
        scaleSetEvictionPolicy: 'Deallocate'
        scaleDownMode: 'Deallocate'
        spotMaxPrice: -1
        availabilityZones: [
          '3'
        ]
        osType: 'Linux'
        osSKU: 'Mariner'
        vnetSubnetID: vnet.properties.subnets[0].id
        podSubnetID: vnet.properties.subnets[4].id
        nodeLabels: {
          hardware: 'intel'
        }
      }
    ]
  }
}
