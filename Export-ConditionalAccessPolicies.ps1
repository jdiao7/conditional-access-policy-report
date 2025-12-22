<#
Export-ConditionalAccessPolicies.ps1
Exports Microsoft Entra Conditional Access policies via Microsoft Graph to a CSV report.
#>


Connect-MgGraph -Scopes "Policy.Read.All", "Directory.Read.All"

$policies = Get-MgIdentityConditionalAccessPolicy



# Define output path
$outputFolder = "C:\Scripts"
$outputFile = Join-Path $outputFolder "DynamicPolicyReport.csv"

# Create folder if it doesn't exist
if (-not (Test-Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory -Force
}

# Prepare data collection array
$exportData = @()

foreach ($policy in $policies) {
    $obj = [ordered]@{}

    $obj["PolicyName"] = $policy.DisplayName
    $obj["PolicyId"] = $policy.Id
    $obj["State"] = $policy.State

    # User/Group/Role counts only
    $obj["IncludedUsersCount"] = $policy.Conditions.Users.IncludeUsers.Count
    $obj["ExcludedUsersCount"] = $policy.Conditions.Users.ExcludeUsers.Count
    $obj["IncludedGroupsCount"] = $policy.Conditions.Users.IncludeGroups.Count
    $obj["ExcludedGroupsCount"] = $policy.Conditions.Users.ExcludeGroups.Count
    $obj["IncludedRolesCount"] = $policy.Conditions.Users.IncludeRoles.Count
    $obj["ExcludedRolesCount"] = $policy.Conditions.Users.ExcludeRoles.Count

    # Risk levels
    $obj["UserRiskLevels"] = $policy.Conditions.UserRiskLevels -join ', '
    $obj["SignInRiskLevels"] = $policy.Conditions.SignInRiskLevels -join ', '
    $obj["InsiderRiskLevels"] = $policy.Conditions.InsiderRiskLevels -join ', '

    # Locations
    $obj["IncludeLocations"] = $policy.Conditions.Locations.IncludeLocations -join ', '
    $obj["ExcludeLocations"] = $policy.Conditions.Locations.ExcludeLocations -join ', '

    # Client apps
    $obj["ClientAppTypes"] = $policy.Conditions.ClientApplications.IncludeClientAppTypes -join ', '

    #Authentication Flows
    $obj["AuthenticationFlows"] = $policy.Conditions.AuthenticationFlows.TransferMethods -join ', '

    # Grant controls
    if ($policy.GrantControls) {
        $obj["GrantOperator"] = $policy.GrantControls.Operator
        $obj["BuiltInControls"] = $policy.GrantControls.BuiltInControls -join ', '
        $obj["TermsOfUse"] = $policy.GrantControls.TermsOfUse -join ', '
        $obj["CustomAuthenticationFactors"] = $policy.GrantControls.CustomAuthenticationFactors -join ', '
    } else {
        $obj["GrantControls"] = "None"
    }

    # Session controls
    if ($policy.SessionControls) {
        $obj["SessionControlsPresent"] = "Yes"
        if ($policy.SessionControls.SignInFrequency) {
            $obj["SignInFrequency"] = "$($policy.SessionControls.SignInFrequency.Value)$($policy.SessionControls.SignInFrequency.Type)"
        }
      
    }

    $exportData += [PSCustomObject]$obj
}

# Export to CSV
$exportData | Export-Csv -Path $outputFile -NoTypeInformation

# Open the CSV in default viewer
Invoke-Item $outputFile
