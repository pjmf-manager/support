Function Get-JCParallelValidation {
    begin {
        $CurrentPSVersion = $PSVersionTable.PSVersion.Major
    }
    process {
        if ($CurrentPSVersion -ge 7) {
            Write-Debug "PSVersion greater than 7"
            Set-JCSettings -parallelEligible $true
            # $ParallelValidation = $true
        } else {
            Write-Warning "The installed version of PowerShell does not support Parallel functionality. Consider updating to PowerShell 7 to use this feature."
            Write-Warning "Visit aka.ms/powershell-release?tag=stable for latest release"
            Write-Debug "Invalid Parallel, unsupported configuration"
            Set-JCSettings -parallelEligible $false
            # $ParallelValidation = $false
        }
    }
    end {
        return (Get-JCSettingsFile).parallel.eligible
    }
}