Configuration DscPullNode {
  Node $AllNodes.NodeName {
      LocalConfigurationManager {
          CertificateID        = "95B14F52F627E44E974C23AFCEF6CBB5F8411552"
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
          CertificateFile = "F:\setup\dscpublickey.cer"
      }
  ) 
}

PullNode -OutputPath 'f:\configs\PullNode' -ConfigurationData $cd
Set-DscLocalConfigurationManager -Path f:\configs\PullNode -Verbose -ComputerName sp
#Start-DscConfiguration -Path f:\dsc\PullNode -ComputerName sp -Wait -Force -Verbose

