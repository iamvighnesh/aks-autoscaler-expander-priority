targetScope = 'subscription'

param clusterResourceGroupName string = 'rg-eus-aksautoscaler-priority'
param clusterResourceGroupLocation string = 'eastus'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: clusterResourceGroupName
  location: clusterResourceGroupLocation
}
