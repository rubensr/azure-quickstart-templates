Task Default -depends Compile

Task Compile {
    .\SPWFE.ps1
}

Task Deploy {
    Publish-DSCModuleAndMof -Source F:\configs\SPWFE -ModuleNameList @('xTimeZone', 'PSDesiredStateConfiguration') -Force
}

Task SetupNodes {
    .\DscPullNodes.ps1
}

Task TestServer {
    .\PullServerSetupTests.ps1
}