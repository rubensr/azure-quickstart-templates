Configuration General {
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
    )
    Import-DscResource -ModuleName xTimeZone, SystemLocaleDsc, PSDesiredStateConfiguration

    Node GeneralConfig {
        Group TestGroup {
            GroupName = "TestGroup"
            Ensure = "Present"
            Credential = $Credential
        }

        SystemLocale SystemLocaleExample {
            SystemLocale = "en-US"
            IsSingleInstance = "Yes"
        }

        xTimeZone TimeZoneExample {
            TimeZone = "Cen. Australia Standard Time" 
            #TimeZone = "Eastern Standard Time"
            IsSingleInstance = "Yes"
        }
    }
}

$cd = @{
    AllNodes = @(    
        @{ 
            NodeName = "GeneralConfig"
            CertificateFile = "F:\pwsh\dscencrypt.cer"
        }
    ) 
}

General -OutputPath 'f:\dsc\General' -ConfigurationData $cd -Credential (Get-Credential -Message 'Enter Credential for configuration')
New-DscChecksum -Path 'f:\dsc\General\GeneralConfig.mof'
