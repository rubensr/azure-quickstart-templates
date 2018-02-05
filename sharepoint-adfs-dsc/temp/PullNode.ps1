Configuration PullNode {
    Node $AllNodes.NodeName {
        LocalConfigurationManager {
            CertificateID = "FE239F0051809E9A3AC2DF53234557990CCD0C44"
            RefreshMode          = 'Pull'
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded   = $true
        }

    }
}

$cd = @{
    AllNodes = @(    
        @{ 
            NodeName = "sp"
            CertificateFile = "F:\pwsh\dscencrypt.cer"
        }
    ) 
}

PullNode -OutputPath 'f:\dsc\PullNode' -ConfigurationData $cd
Set-DscLocalConfigurationManager -Path f:\dsc\PullNode -Verbose -ComputerName sp
#Start-DscConfiguration -Path f:\dsc\PullNode -ComputerName sp -Wait -Force -Verbose

