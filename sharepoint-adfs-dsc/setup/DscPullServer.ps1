Configuration DscPullServer {
    param(
        [string[]]$NodeName = "localhost", 

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]  $RegistrationKey       = "4826093e-3611-463c-bec4-571ea9f280ec",

        [ValidateNotNullOrEmpty()] 
        [String]  $CertificateThumbprint = "1A01A0E90FD240C665A745718A1AAE08BFB99B82",
        
        [Boolean] $DSCSelfSignedCerts    = $true,
        
        [Int]     $DSCPort               = 8080
    )
    
    Node $NodeName {
        WindowsFeature DSCServiceFeature {
            Ensure = "Present"
            Name   = "DSC-Service"
        }

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