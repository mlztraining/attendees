# Generate random IP Address Plan and Resource Prefix for MLZ parameter file
Param
(
    # Path to MLZ JSON parameter file
    [Parameter(HelpMessage = "Path to the MLZ deployment parameter JSON file")]
    [ValidateScript({Test-Path $_})]
    [string]
    $mlzParameterFile = (Join-Path -Path (Split-Path $script:MyInvocation.MyCommand.Path) -ChildPath "mlz.parameters.json")
)

# Generate random /21 IP address plan
$ipPlan = @{
    "digit1" = "10"
    "digit2" = Get-Random -Minimum 0 -Maximum 256
    "digit3" = (Get-Random -Minimum 0 -Maximum 8) * 32
}
# Supernet
$ipPlan.Add("supernetAddress",($ipPlan.digit1 + "." + $ipPlan.digit2 + "." + $ipPlan.digit3 + ".0"))
$ipPlan.Add("supernetAddressPrefix", ($ipPlan.supernetAddress + "/21"))
Write-Output ("Generating IP Address plan in random supernet " + $ipPlan.supernetAddressPrefix + "...")
# Hub
$ipPlan.Add("hubAddressSpace",$ipPlan.supernetAddress)
$ipPlan.Add("hubAddressSpaceWithPrefix",($ipPlan.hubAddressSpace + "/23"))
$ipPlan.Add("hubHubSubnetAddress",$ipPlan.hubAddressSpace)
$ipPlan.Add("hubHubSubnetAddressWithPrefix",($ipPlan.hubHubSubnetAddress + "/25"))
$ipPlan.Add("hubBastionSubnetAddress",($ipPlan.digit1 + "." + $ipPlan.digit2 + "." + ($ipPlan.digit3 + 1) + ".0"))
$ipPlan.Add("hubBastionSubnetAddressWithPrefix",($ipPlan.hubBastionSubnetAddress + "/26"))
$ipPlan.Add("hubFirewallSubnetAddress",($ipPlan.digit1 + "." + $ipPlan.digit2 + "." + ($ipPlan.digit3 + 1) + ".64"))
$ipPlan.Add("hubFirewallSubnetAddressWithPrefix",($ipPlan.hubFirewallSubnetAddress + "/26"))
$ipPlan.Add("hubFirewallMgmtSubnetAddress",($ipPlan.digit1 + "." + $ipPlan.digit2 + "." + ($ipPlan.digit3 + 1) + ".128"))
$ipPlan.Add("hubFirewallMgmtSubnetAddressWithPrefix",($ipPlan.hubFirewallMgmtSubnetAddress + "/26"))
# Identity
$ipPlan.Add("identityAddressSpace",($ipPlan.digit1 + "." + $ipPlan.digit2 + "." + ($ipPlan.digit3 + 2) + ".0"))
$ipPlan.Add("identityAddressSpaceWithPrefix",($ipPlan.identityAddressSpace + "/25"))
$ipPlan.Add("identityIdentitySubnetAddress",$ipPlan.identityAddressSpace)
$ipPlan.Add("identityIdentityAddressWithPrefix",($ipPlan.identityIdentitySubnetAddress + "/26"))
# Operations
$ipPlan.Add("operationsAddressSpace",($ipPlan.digit1 + "." + $ipPlan.digit2 + "." + ($ipPlan.digit3 + 2) + ".128"))
$ipPlan.Add("operationsAddressSpaceWithPrefix",($ipPlan.operationsAddressSpace + "/25"))
$ipPlan.Add("operationsOperationsSubnetAddress",$ipPlan.operationsAddressSpace)
$ipPlan.Add("operationsOperationsAddressWithPrefix",($ipPlan.operationsOperationsSubnetAddress + "/26"))
# SharedServices
$ipPlan.Add("sharedsvcAddressSpace",($ipPlan.digit1 + "." + $ipPlan.digit2 + "." + ($ipPlan.digit3 + 3) + ".0"))
$ipPlan.Add("sharedsvcAddressSpaceWithPrefix",($ipPlan.sharedsvcAddressSpace + "/25"))
$ipPlan.Add("sharedsvcSharedsvcSubnetAddress",$ipPlan.sharedsvcAddressSpace)
$ipPlan.Add("sharedsvcSharedsvcAddressWithPrefix",($ipPlan.sharedsvcSharedsvcSubnetAddress + "/26"))

# Generate random resource prefix
$resourcePrefix = ([char](Get-Random -Minimum 97 -Maximum 123) + [char](Get-Random -Minimum 97 -Maximum 123) + [char](Get-Random -Minimum 97 -Maximum 123) + [char](Get-Random -Minimum 97 -Maximum 123))
Write-Output ("Generated random resource prefix " + $resourcePrefix)

# Edit parameter file
$mlzParamFile = Get-Content -Path $mlzParameterFile
if(!($mlzParamFile)){Write-Error -Message ("Could not open parameter file " + [char]34 + $mlzParameterFile + [char]34);exit}
$mlzParam = $mlzParamFile | ConvertFrom-Json
if(!($mlzParam)){Write-Error -Message "Could not convert parameter from JSON";exit}
$mlzParam.parameters.resourcePrefix.value = $resourcePrefix
$mlzParam.parameters.firewallSupernetIPAddress.value = $ipPlan.supernetAddressPrefix
$mlzParam.parameters.hubVirtualNetworkAddressPrefix.value = $ipPlan.hubAddressSpaceWithPrefix
$mlzParam.parameters.hubSubnetAddressPrefix.value = $ipPlan.hubHubSubnetAddressWithPrefix
$mlzParam.parameters.bastionHostSubnetAddressPrefix.value = $ipPlan.hubBastionSubnetAddressWithPrefix
$mlzParam.parameters.firewallClientSubnetAddressPrefix.value = $ipPlan.hubFirewallSubnetAddressWithPrefix
$mlzParam.parameters.firewallManagementSubnetAddressPrefix.value = $ipPlan.hubFirewallMgmtSubnetAddressWithPrefix
$mlzParam.parameters.identityVirtualNetworkAddressPrefix.value = $ipPlan.identityAddressSpaceWithPrefix
$mlzParam.parameters.identitySubnetAddressPrefix.value = $ipPlan.identityIdentityAddressWithPrefix
$mlzParam.parameters.operationsVirtualNetworkAddressPrefix.value = $ipPlan.operationsAddressSpaceWithPrefix
$mlzParam.parameters.operationsSubnetAddressPrefix.value = $ipPlan.operationsOperationsAddressWithPrefix
$mlzParam.parameters.sharedServicesVirtualNetworkAddressPrefix.value = $ipPlan.sharedsvcAddressSpaceWithPrefix
$mlzParam.parameters.sharedServicesSubnetAddressPrefix.value = $ipPlan.sharedsvcSharedsvcAddressWithPrefix
Write-Output ("Saving " + [char]34 + $mlzParameterFile + [char]34 + " with edited parameters!")
$mlzParam | ConvertTo-Json -Depth 10 | Out-File -FilePath $mlzParameterFile