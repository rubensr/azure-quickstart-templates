Task Default -depends Compile

Task Compile {
    .\General.ps1
}

Task Deploy {
    Publish-DSCModuleAndMof -Source F:\dsc\General -ModuleNameList @('xTimeZone', 'SystemLocaleDsc', 'PSDesiredStateConfiguration') -Force
}

Task SetupNodes {
    .\PullNode.ps1
}

Task TestServer {
    .\PullServerSetupTests.ps1
}