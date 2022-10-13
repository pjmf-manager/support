Function New-JCUserGroup () {
    [CmdletBinding()]
    param
    (

        [Parameter(Mandatory,
            ValueFromPipelineByPropertyName = $True,
            HelpMessage = 'The name of the new JumpCloud User Group.')]
        [string]
        $GroupName
    )

    begin {
        Write-Debug 'Verifying JCAPI Key'
        if ($JCAPIKEY.length -ne 40) { Connect-JConline }

        Write-Debug 'Populating API headers'
        $hdrs = @{

            'Content-Type' = 'application/json'
            'Accept'       = 'application/json'
            'X-API-KEY'    = $JCAPIKEY

        }

        if ($JCOrgID) {
            $hdrs.Add('x-org-id', "$($JCOrgID)")
        }

        $URI = "$JCUrlBasePath/api/v2/usergroups"
        $NewGroupsArrary = @()

    }

    process {

        foreach ($Group in $GroupName) {
            $body = @{
                'name' = $Group
            }

            $jsonbody = ConvertTo-Json $body

            try {
                $NewGroup = Invoke-RestMethod -Method POST -Uri $URI  -Body $jsonbody -Headers $hdrs -UserAgent:(Get-JCUserAgent)
                $Status = 'Created'
            } catch {
                $Status = $_.ErrorDetails
            }
            $FormattedResults = [PSCustomObject]@{

                'Name'   = $Group
                'id'     = $NewGroup.id
                'Result' = $Status
            }

            $NewGroupsArrary += $FormattedResults
        }
    }

    end {
        return $NewGroupsArrary
    }
}