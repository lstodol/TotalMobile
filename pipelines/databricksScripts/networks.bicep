param vnetName string
param location string
param networkSecurityGroupName string
param vNetGatewayName string
param awsGatewaySharedKey string
param includeAWSResources bool

@description('The name of the subnet to where the dbx clusters will be encapsulated.')
param containerSubnetName string

@description('The name of the subnet to where the dbx host will be encapsulated.')
param hostSubnetName string

@description('The name of the subnet where communication to AWS is allowed.')
param gatewaySubnetName string

var baseSecurityRules = [
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound'
    properties: {
      description: 'Required for worker nodes communication within a cluster.'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 103
      direction: 'Inbound'
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp1'
    properties: {
      description: 'Required for workers communication with Databricks Webapp.'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'AzureDatabricks'
      access: 'Allow'
      priority: 100
      direction: 'Outbound'
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp2'
    properties: {
      description: 'Required for workers communication with Databricks Webapp.'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3306'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'AzureDatabricks'
      access: 'Allow'
      priority: 110
      direction: 'Outbound'
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp3'
    properties: {
      description: 'Required for workers communication with Databricks Webapp.'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '8443-8451'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'AzureDatabricks'
      access: 'Allow'
      priority: 111
      direction: 'Outbound'
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql'
    properties: {
      description: 'Required for workers communication with Azure SQL services.'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '3306'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'Sql'
      access: 'Allow'
      priority: 101
      direction: 'Outbound'
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage'
    properties: {
      description: 'Required for workers communication with Azure Storage services.'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '443'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'Storage'
      access: 'Allow'
      priority: 102
      direction: 'Outbound'
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound'
    properties: {
      description: 'Required for worker nodes communication within a cluster.'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
      access: 'Allow'
      priority: 103
      direction: 'Outbound'
    }
  }
  {
    name: 'Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub'
    properties: {
      description: 'Required for worker communication with Azure Eventhub services.'
      protocol: 'Tcp'
      sourcePortRange: '*'
      destinationPortRange: '9093'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'EventHub'
      access: 'Allow'
      priority: 104
      direction: 'Outbound'
    }
  }
]

var awsSecurityRules = [
  {
    name: 'AllowAWSVPCAccessToVNET'
    properties: {
      description: 'Required for worker communication with Azure Eventhub services.'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: '10.16.0.0/16'
      access: 'Allow'
      priority: 121
      direction: 'Inbound'
    }
  }
  {
    name: 'AllowVNETAccessToAWSVPC'
    properties: {
      description: 'Required for worker communication with Azure Eventhub services.'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: '10.16.0.0/16'
      access: 'Allow'
      priority: 121
      direction: 'Outbound'
    }
  }
]

var securityRules = concat(baseSecurityRules, includeAWSResources ? awsSecurityRules : [])

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: securityRules
  }
}


// vnet was already create on all env, so to walkaround problem with not deleteing subnets and recreating them, existing resources is taken
// resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' = {
//   name: vnetName
//   location: location
//   properties: {
//     addressSpace: {
//       addressPrefixes: [ '10.0.0.0/16' ]
//     }
//   }
// }

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  name: vnetName
}

resource hostSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: hostSubnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: '10.0.1.0/24'
    networkSecurityGroup: {
      id: nsg.id
    }
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.KeyVault'
      }
      {
        service: 'Microsoft.EventHub'
      }
    ]
    delegations: [
      {
        name: 'databricks-del-public'
        properties: {
          serviceName: 'Microsoft.Databricks/workspaces'
        }
      }
    ]
  }
}

resource containerSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = {
  name: containerSubnetName
  parent: virtualNetwork
  properties: {
    addressPrefix: '10.0.2.0/24'
    networkSecurityGroup: {
      id: nsg.id
    }
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.KeyVault'
      }
      {
        service: 'Microsoft.EventHub'
      }
    ]
    delegations: [
      {
        name: 'databricks-del-private'
        properties: {
          serviceName: 'Microsoft.Databricks/workspaces'
          }
        }
      ]
    }
  }

  resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' = if (includeAWSResources) {
    name: gatewaySubnetName
    parent: virtualNetwork
    properties: {
      addressPrefix: '10.0.0.0/24'
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Enabled'
      serviceEndpoints: [
        {
          service: 'Microsoft.Storage'
        }
        {
          service: 'Microsoft.KeyVault'
        }
        {
          service: 'Microsoft.EventHub'
        }
      ]
    }
  }

resource publicIPAddress1 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (includeAWSResources) {
  name: 'pub-ip-aws-1'
  location: location
  properties: {
    ipAddress: '51.140.109.16'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  } 
  sku:{
    name: 'Standard'
    tier: 'Regional'
  }
}

resource publicIPAddress2 'Microsoft.Network/publicIPAddresses@2023-11-01' = if (includeAWSResources) {
  name: 'pub-ip-aws-2'
  location: location
  properties: {
    ipAddress: '51.143.189.75'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  } 
  sku:{
    name: 'Standard'
    tier: 'Regional'
  }
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-11-01' = if (includeAWSResources) {
  name: 'aws-transit-gateway-18.200.54.187'
  location: location
  properties: {
    gatewayIpAddress: '18.200.54.187'
    bgpSettings: {
      asn: 64512
      bgpPeeringAddress: '169.254.21.37'
      peerWeight: 0
    }
  } 
}

resource vNetGateway 'Microsoft.Network/virtualNetworkGateways@2023-11-01' = if (includeAWSResources) {
  name: vNetGatewayName
  location: location
  properties: {
    enablePrivateIpAddress: false
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress1.id
          }
          subnet: {
            id: '${virtualNetwork.id}/subnets/GatewaySubnet'
          }
        }
      }
      {
        name: 'activeActive'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress2.id
          }
          subnet: {
            id: '${virtualNetwork.id}/subnets/GatewaySubnet'
          }
        }
      }
    ]
    natRules: [
      {
        name: 'nat-out-1'
        properties: {
          type: 'Static'
          mode: 'EgressSnat'
          internalMappings: [
            {
              addressSpace: '10.0.1.0/24'
            }
          ]
          externalMappings: [
            {
              addressSpace: '10.180.1.0/24'
            }
          ]
        }
      }
      {
        name: 'nat-out-2'
        properties: {
          type: 'Static'
          mode: 'EgressSnat'
          internalMappings: [
            {
              addressSpace: '10.0.2.0/24'
            }
          ]
          externalMappings: [
            {
              addressSpace: '10.180.2.0/24'
            }
          ]
        }
      }
    ]
    virtualNetworkGatewayPolicyGroups: []
    enableBgpRouteTranslationForNat: true
    disableIPSecReplayProtection: false
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: true
    activeActive: true
    bgpSettings: {
      asn: 64591
      bgpPeeringAddress: '10.0.0.4,10.0.0.5'
      peerWeight: 0
      bgpPeeringAddresses: [
        {
          ipconfigurationId: resourceId('Microsoft.Network/virtualNetworkGateways/ipConfigurations', vNetGatewayName, 'default')
          customBgpIpAddresses: [
            '169.254.21.38'
          ]
        }
        { 
          ipconfigurationId: resourceId('Microsoft.Network/virtualNetworkGateways/ipConfigurations', vNetGatewayName, 'activeActive')
          customBgpIpAddresses: [
            '169.254.21.42'
          ]
        }
      ]
    }
    vpnGatewayGeneration: 'Generation2'
    allowRemoteVnetTraffic: false
    allowVirtualWanTraffic: false
  }
}

resource transitGatewayConnection 'Microsoft.Network/connections@2023-11-01' = if (includeAWSResources) {
  name: 'aws-transit-gateway-18.200.54.187'
  location: location

  properties: {
    virtualNetworkGateway1: {
      id: vNetGateway.id
      properties:{}
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
      properties:{}
    }
    egressNatRules: [
      {
        id: '${vNetGateway.id}/natRules/nat-out-1'
      }
      {
        id: '${vNetGateway.id}/natRules/nat-out-2'
      }
    ]
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    routingWeight: 0
    sharedKey: awsGatewaySharedKey
    enableBgp: true
    useLocalAzureIpAddress: false
    usePolicyBasedTrafficSelectors: false
    ipsecPolicies: []
    trafficSelectorPolicies: []
    expressRouteGatewayBypass: false
    enablePrivateLinkFastPath: false
    dpdTimeoutSeconds: 45
    connectionMode: 'Default'
    gatewayCustomBgpIpAddresses: []
  }
}

// Output the IDs of the subnets
output hostSubnetId string = hostSubnet.id
output containerSubnetId string = containerSubnet.id
output vnetId string = virtualNetwork.id

