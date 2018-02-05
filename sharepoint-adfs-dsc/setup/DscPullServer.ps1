Configuration DscPullServer {
    param(
        [string[]]$NodeName              = "localhost", 

        [ValidateNotNullOrEmpty()]
        [String]  $RegistrationKey       = "4826093e-3611-463c-bec4-571ea9f280ec",

        [ValidateNotNullOrEmpty()] 
        [String]  $CertificateThumbprint = "1A01A0E90FD240C665A745718A1AAE08BFB99B82",
        
        [Boolean] $DSCSelfSignedCerts    = $true,
        
        [Int]     $DSCPort               = 8080
    )
    
    Import-DSCResource -ModuleName xPSDesiredStateConfiguration
    Import-DSCResource -ModuleName xWebAdministration
    Import-DSCResource -ModuleName PSDesiredStateConfiguration

    Node $NodeName {
        WindowsFeature IIS {
            Ensure = "Present"
            Name   = "Web-Server"
        }

        WindowsFeature IISManagementTools {
            Ensure    = "Present"
            Name      = "Web-Mgmt-Tools"
            DependsOn = "[WindowsFeature]IIS"
        }

        WindowsFeature DSCServiceFeature {
            Ensure    = "Present"
            Name      = "DSC-Service"
            DependsOn = "[WindowsFeature]IIS"
        }

        xWebAppPool RemoveDotNet2Pool         { Name = ".NET v2.0";            Ensure = "Absent"}
        xWebAppPool RemoveDotNet2ClassicPool  { Name = ".NET v2.0 Classic";    Ensure = "Absent"}
        xWebAppPool RemoveDotNet45Pool        { Name = ".NET v4.5";            Ensure = "Absent"}
        xWebAppPool RemoveDotNet45ClassicPool { Name = ".NET v4.5 Classic";    Ensure = "Absent"}
        xWebAppPool RemoveClassicDotNetPool   { Name = "Classic .NET AppPool"; Ensure = "Absent"}
        xWebAppPool RemoveDefaultAppPool      { Name = "DefaultAppPool";       Ensure = "Absent"}
        xWebSite    RemoveDefaultWebSite      { Name = "Default Web Site";     Ensure = "Absent"; PhysicalPath = "C:\inetpub\wwwroot"}

        xDscWebService PSDSCPullServer {
            Ensure                          = "Present"
            EndpointName                    = "PSDSCPullServer"
            Port                            = $DSCPort
            PhysicalPath                    = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
            ModulePath                      = "$env:PROGRAMFILES\WindowsPowershell\DscService\Modules"
            ConfigurationPath               = "$env:PROGRAMFILES\WindowsPowershell\DscService\Configuration"
            RegistrationKeyPath             = "$env:PROGRAMFILES\WindowsPowerShell\DscService"   
            UseSecurityBestPractices        = $true
            CertificateThumbprint           = $CertificateThumbprint
            AcceptSelfSignedCertificates    = $DSCSelfSignedCerts
            State                           = "Started"
            DependsOn                       = "[WindowsFeature]DSCServiceFeature"
        }

        File RegistrationKeyFile
        {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents        = $RegistrationKey
        }
    }
}

DscPullServer -OutputPath f:\Configs\PullServer
Start-DscConfiguration -Path f:\Configs\PullServer -Wait -Verbose -Force
