# File: Create-DnsServer.psm1
function New-DnsServer {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DnsServerName,
        
        [Parameter(Mandatory=$true)]
        [ipaddress]$PrimaryIpAddress,
        
        [Parameter(Mandatory=$false)]
        [ipaddress]$SecondaryIpAddress,
        
        [Parameter(Mandatory=$true)]
        [string[]]$ForwardLookupZones,
        
        [Parameter(Mandatory=$true)]
        [string[]]$ReverseLookupZones
    )
    
    # Install DNS Server role
    Install-WindowsFeature -Name DNS

    # Install DNS Server role
    Add-WindowsFeature -Name DNS -IncludeManagementTools
    
    # Configure DNS Server
    $dnsParams = @{
        ComputerName = $env:COMPUTERNAME
        PrimaryServer = $PrimaryIpAddress
        SecondaryServer = $SecondaryIpAddress
        Forwarders = @()
    }
    
    Set-DnsServerSettings @dnsParams
    
    # Create forward lookup zones
    foreach ($zone in $ForwardLookupZones) {
        Add-DnsServerPrimaryZone -Name $zone -ZoneFile "$zone.dns"
    }
    
    # Create reverse lookup zones
    foreach ($zone in $ReverseLookupZones) {
        Add-DnsServerPrimaryZone -NetworkId $zone -ZoneFile "$zone.ptr"
    }

    Write-Output "DNS Server '$DnsServerName' created successfully."
}

# Function to modify DNS server settings
function Modify-DnsServer {
    param(
        [string]$InterfaceAlias,
        [string[]]$DnsServerAddresses,
        [switch]$ResetAddresses
    )
    
    if ($ResetAddresses) {
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ResetServerAddresses
    } else {
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $DnsServerAddresses
    }
}

# Function to secure DNS server
function Secure-DnsServer {
    # Enable DNSSEC validation
    Set-DnsServerDnsSecValidation -Enabled $true
    
    # Enable logging
    Set-DnsServerDebugLogging -Enable $true -FileMaxSize 100MB
    
    # Disable recursion
    Set-DnsServerRecursion -Enabled $false
    
    # Restrict zone transfers
    Get-DnsServerZone | Where-Object {$_.IsAutoCreated -eq $false} | Set-DnsServerZone -SecureSecondaries TransferToAnyServer
    
    # Enable global query block list
    # blocks queries doubt its a security feature
    # dnscmd /config /enableglobalqueryblocklist 1
    
    # Enable DNS diagnostic logging for ServerLevelPluginDLLEvent
    Set-DnsServerDiagnostics -EnableLoggingForPluginDllEvent $true
    
    # Configure DNS rate limiting
    Set-DnsServerRRL -Mode Enable -Force
    Set-DnsServerResponseRateLimiting -ResetToDefault -Force
    
    # Protect against cache poisoning from fragmentation attacks
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\DNS\Parameters" -Name MaximumUdpPacketSize -Type DWord -Value 0x4C5 -Force
}
# Function to convert zone to Active Directory-integrated
function Convert-ToADIntegrated {
    param([string]$ZoneName)
    Add-DnsServerPrimaryZone -Name $ZoneName -ReplicationScope Domain
}

# Function to sign zone
function Sign-Zone {
    param([string]$ZoneName)
    Add-DnsServerSigningKey -ZoneName $ZoneName -ActiveDirectoryReplicationScope Forest -UseDefaultOptions
}

function Sign-AllZones {
    # Main script
    $zones = Get-DnsServerZone | Where-Object {$_.IsAutoCreated -eq $false}
    foreach ($zone in $zones) {
        Convert-ToADIntegrated -ZoneName $zone.ZoneName
        Sign-Zone -ZoneName $zone.ZoneName
    }   
}

Export-ModuleMember -Function New-DnsServer, Secure-DnsServer, Sign-AllZones