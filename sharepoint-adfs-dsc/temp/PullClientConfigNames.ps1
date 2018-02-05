[DSCLocalConfigurationManager()]
configuration PullClientConfigNames
{
    Node sp
    {
        Settings
        {
            CertificateID = "FE239F0051809E9A3AC2DF53234557990CCD0C44"
            RefreshMode          = 'Pull'
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded   = $true
        }

        ConfigurationRepositoryWeb CONTOSO-PullSrv
        {
            ServerURL          = 'https://dc.contoso.local:8080/psdscpullserver.svc'
            RegistrationKey    = '4826093e-3611-463c-bec4-571ea9f280ec'
            AllowUnsecureConnection = $false
            ConfigurationNames = @('GeneralConfig')
        }   

        ReportServerWeb CONTOSO-PullSrv
        {
            ServerURL       = 'https://dc.contoso.local:8080/psdscpullserver.svc'
            RegistrationKey = '4826093e-3611-463c-bec4-571ea9f280ec'
            AllowUnsecureConnection = $false
        }
    }
}

PullClientConfigNames
