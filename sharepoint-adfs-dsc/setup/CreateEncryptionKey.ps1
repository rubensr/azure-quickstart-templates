param(
  # Parameter help description
  [Parameter(Mandatory=$true)]
  [String]
  $pwd,

  [Parameter(Mandatory=$true)]
  [String]
  $path
)
# note: These steps need to be performed in an Administrator PowerShell session
$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' -HashAlgorithm SHA256
# export the private key certificate
$mypwd = ConvertTo-SecureString -String $pwd -Force -AsPlainText
$cert | Export-PfxCertificate -FilePath "$path\DscPrivateKey.pfx" -Password $mypwd -Force
# remove the private key certificate from the node but keep the public key certificate
$cert | Export-Certificate -FilePath "$path\DscPublicKey.cer" -Force
$cert | Remove-Item -Force
Import-Certificate -FilePath "$path\DscPublicKey.cer" -CertStoreLocation Cert:\LocalMachine\My