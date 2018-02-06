[DSCLocalConfigurationManager()]
configuration PullClientConfigNames
{
    Node sp
    {
        Settings
        {
            CertificateID        = "95B14F52F627E44E974C23AFCEF6CBB5F8411552"
            RefreshMode          = 'Pull'
            RefreshFrequencyMins = 30
            RebootNodeIfNeeded   = $true
        }

        ConfigurationRepositoryWeb CONTOSO-PullSrv
        {
            ServerURL               = 'https://dsc.contoso.local:8080/psdscpullserver.svc'
            RegistrationKey         = '4826093e-3611-463c-bec4-571ea9f280ec'
            AllowUnsecureConnection = $false
            ConfigurationNames      = @('SPWFEConfig')
        }   

        ReportServerWeb CONTOSO-PullSrv
        {
            ServerURL               = 'https://dsc.contoso.local:8080/psdscpullserver.svc'
            RegistrationKey         = '4826093e-3611-463c-bec4-571ea9f280ec'
            AllowUnsecureConnection = $false
        }
    }
}

PullClientConfigNames -OutputPath f:\configs\targetnodes

