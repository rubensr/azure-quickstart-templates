Configuration SPWFE {
  Param (
      [Parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]
      [pscredential]
      $Credential
  )
  Import-DscResource -ModuleName xTimeZone, PSDesiredStateConfiguration

  Node SPWFEConfig {
      Group TestGroup {
          GroupName = "TestGroup"
          Ensure = "Present"
          Credential = $Credential
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
          NodeName = "SPWFEConfig"
          CertificateFile = "F:\setup\dscpublickey.cer"
      }
  ) 
}

SPWFE -OutputPath 'f:\configs\SPWFE' -ConfigurationData $cd -Credential (Get-Credential -Message 'Enter Credential for configuration')
New-DscChecksum -Path 'f:\configs\SPWFE\SPWFEConfig.mof'
