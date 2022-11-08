Describe -Tag:('JCRadiusServer') 'New-JCRadiusServer Tests' {
    BeforeAll {
        $RadiusServerTemplate = Get-JCRadiusServer -Name:($PesterParams_RadiusServer.name); # -Fields:('') -Filter:('') -Limit:(1) -Skip:(1) -Paginate:($true) -Force;
        $AzureRadiusServerTemplate = Get-JCRadiusServer -Name:($PesterParams_AzureRadiusServer.name); # -Fields:('') -Filter:('') -Limit:(1) -Skip:(1) -Paginate:($true) -Force;
    }
    Context 'New-JCRadiusServer' {
        It ('Should create a new radius server.') {
            $RadiusServerTemplate | Remove-JCRadiusServer -Force
            $RadiusServer = $RadiusServerTemplate | New-JCRadiusServer # -Name:('') -networkSourceIp:('') -sharedSecret:('') -Force ;
            $RadiusServer | Should -Not -BeNullOrEmpty
            $RadiusServer.name | Should -Be $RadiusServerTemplate.name
            $RadiusServer.authIdp | Should -Be 'JUMPCLOUD' # This is the defulat authIdp
        }
        It ('Should create a new radius server.') {
            $AzureRadiusServerTemplate | Remove-JCRadiusServer -Force
            $RadiusServer = $RadiusServerTemplate | New-JCRadiusServer # -Name:('') -networkSourceIp:('') -sharedSecret:('') -Force ;
            $RadiusServer | Should -Not -BeNullOrEmpty
            $RadiusServer.name | Should -Be $RadiusServerTemplate.name
            $RadiusServer.authIdp | Should -Be $RadiusServerTemplate.authIdp
            # clean up
            Remove-JCRadiusServer -id $RadiusServer.id
        }
    }
}