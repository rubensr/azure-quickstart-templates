configuration ConfigureSPVM
{
    param
    (
        [Parameter(Mandatory)]
        [String]$DNSServer,

        [Parameter(Mandatory)]
        [String]$DomainFQDN,

        [Parameter(Mandatory)]
        [String]$DCName,

        [Parameter(Mandatory)]
        [String]$SQLName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$DomainAdminCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SPSetupCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SPFarmCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SPSvcCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SPAppPoolCreds,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$SPPassphraseCreds,

        [String] $SPTrustedSitesName = "SPSites"
    )

    Import-DscResource -ModuleName xComputerManagement, xDisk, cDisk, xNetworking, xActiveDirectory, xCredSSP, xWebAdministration, SharePointDsc, xPSDesiredStateConfiguration, xDnsServer, xCertificate

    [String] $DomainNetbiosName = (Get-NetBIOSName -DomainFQDN $DomainFQDN)
    $Interface=Get-NetAdapter| Where-Object Name -Like "Ethernet*"| Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)
    [System.Management.Automation.PSCredential] $DomainAdminCredsQualified = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($DomainAdminCreds.UserName)", $DomainAdminCreds.Password)
    [System.Management.Automation.PSCredential] $SPSetupCredsQualified = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($SPSetupCreds.UserName)", $SPSetupCreds.Password)
    [System.Management.Automation.PSCredential] $SPFarmCredsQualified = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($SPFarmCreds.UserName)", $SPFarmCreds.Password)
    [System.Management.Automation.PSCredential] $SPSvcCredsQualified = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($SPSvcCreds.UserName)", $SPSvcCreds.Password)
    [System.Management.Automation.PSCredential] $SPAppPoolCredsQualified = New-Object System.Management.Automation.PSCredential ("${DomainNetbiosName}\$($SPAppPoolCreds.UserName)", $SPAppPoolCreds.Password)
    [String] $SPDBPrefix = "SP16DSC_"
    [Int] $RetryCount = 30
    [Int] $RetryIntervalSec = 30
    $ComputerName = Get-Content env:computername
    $LdapcpLink = (Get-LatestGitHubRelease -repo "Yvand/LDAPCP" -artifact "LDAPCP.wsp")

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        #**********************************************************
        # Initialization of VM
        #**********************************************************

        xWaitforDisk Disk2
        {
            DiskNumber = 2
            RetryIntervalSec = $RetryIntervalSec
            RetryCount = $RetryCount
        }
        cDiskNoRestart SPDataDisk
        {
            DiskNumber = 2
            DriveLetter = "F"
            DependsOn = "[xWaitforDisk]Disk2"
        }
        WindowsFeature ADPS     { Name = "RSAT-AD-PowerShell"; Ensure = "Present"; DependsOn = "[cDiskNoRestart]SPDataDisk" }
        WindowsFeature DnsTools { Name = "RSAT-DNS-Server";    Ensure = "Present"; DependsOn = "[cDiskNoRestart]SPDataDisk"  }
        xDnsServerAddress DnsServerAddress
        {
            Address        = $DNSServer
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
            DependsOn="[WindowsFeature]ADPS"
        }

        xCredSSP CredSSPServer { Ensure = "Present"; Role = "Server"; DependsOn = "[xDnsServerAddress]DnsServerAddress" } 
        xCredSSP CredSSPClient { Ensure = "Present"; Role = "Client"; DelegateComputers = "*.$DomainFQDN", "localhost"; DependsOn = "[xCredSSP]CredSSPServer" }

        #**********************************************************
        # Join AD forest
        #**********************************************************
        xWaitForADDomain DscForestWait
        {
            DomainName = $DomainFQDN
            DomainUserCredential= $DomainAdminCredsQualified
            RetryCount = $RetryCount
            RetryIntervalSec = $RetryIntervalSec
            DependsOn="[xCredSSP]CredSSPClient"
        }

        xComputer DomainJoin
        {
            Name = $ComputerName
            DomainName = $DomainFQDN
            Credential = $DomainAdminCredsQualified
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

    }
}

function Get-LatestGitHubRelease
{
    [OutputType([string])]
    param(
        [string]$repo,
        [string]$artifact
    )
    # Found in https://blog.markvincze.com/download-artifacts-from-a-latest-github-release-in-sh-and-powershell/
    $latestRelease = Invoke-WebRequest https://github.com/$repo/releases/latest -Headers @{"Accept"="application/json"} -UseBasicParsing
    $json = $latestRelease.Content | ConvertFrom-Json
    $latestVersion = $json.tag_name
    $url = "https://github.com/$repo/releases/download/$latestVersion/$artifact"
    return $url
}

function Get-NetBIOSName
{
    [OutputType([string])]
    param(
        [string]$DomainFQDN
    )

    if ($DomainFQDN.Contains('.')) {
        $length=$DomainFQDN.IndexOf('.')
        if ( $length -ge 16) {
            $length=15
        }
        return $DomainFQDN.Substring(0,$length)
    }
    else {
        if ($DomainFQDN.Length -gt 15) {
            return $DomainFQDN.Substring(0,15)
        }
        else {
            return $DomainFQDN
        }
    }
}

function Get-SPDSCInstalledProductVersion
{
    $pathToSearch = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\*\ISAPI\Microsoft.SharePoint.dll"
    $fullPath = Get-Item $pathToSearch | Sort-Object { $_.Directory } -Descending | Select-Object -First 1
    return (Get-Command $fullPath).FileVersionInfo
}

<#
# Azure DSC extension logging: C:\WindowsAzure\Logs\Plugins\Microsoft.Powershell.DSC\2.21.0.0
# Azure DSC extension configuration: C:\Packages\Plugins\Microsoft.Powershell.DSC\2.21.0.0\DSCWork

Install-Module -Name xPendingReboot
help ConfigureSPVM

$DomainAdminCreds = Get-Credential -Credential "yvand"
$SPSetupCreds = Get-Credential -Credential "spsetup"
$SPFarmCreds = Get-Credential -Credential "spfarm"
$SPSvcCreds = Get-Credential -Credential "spsvc"
$SPAppPoolCreds = Get-Credential -Credential "spapppool"
$SPPassphraseCreds = Get-Credential -Credential "Passphrase"
$DNSServer = "10.0.1.4"
$DomainFQDN = "contoso.local"
$DCName = "DC"
$SQLName = "SQL"

ConfigureSPVM -DomainAdminCreds $DomainAdminCreds -SPSetupCreds $SPSetupCreds -SPFarmCreds $SPFarmCreds -SPSvcCreds $SPSvcCreds -SPAppPoolCreds $SPAppPoolCreds -SPPassphraseCreds $SPPassphraseCreds -DNSServer $DNSServer -DomainFQDN $DomainFQDN -DCName $DCName -SQLName $SQLName -ConfigurationData @{AllNodes=@(@{ NodeName="localhost"; PSDscAllowPlainTextPassword=$true })} -OutputPath "C:\Data\\output"
Set-DscLocalConfigurationManager -Path "C:\Data\output\"
Start-DscConfiguration -Path "C:\Data\output" -Wait -Verbose -Force

#>
