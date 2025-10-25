
# $azureConfig = Get-Content -Path '.\config\azure_config.json' | ConvertFrom-Json

# $azureCreds = New-Object System.Management.Automation.PSCredential(
#     $azureConfig.user, 
#     (ConvertTo-SecureString $azureConfig.pwd -AsPlainText -Force)
# )

# Import-Module Microsoft.Graph

function Get-AzureUserGroups{
    param(
        [string]$UserId
    )
    $userGroups = Get-MgUserMemberOf -UserId $UserId
    return $userGroups
}

function Remove-AzureUserGroups{
    param(
        [string]$UserId,
        [array]$Groups
    )

    $userObjectId = (Get-MgUser -UserId $UserId).Id

    foreach ($group in $Groups){
        $groupId = $group.Id
        $groupName = (Get-MgGroup -GroupId $groupId).DisplayName
        Write-Output $groupName
        #TODO try/catch
        #TODO: Write to log
        Remove-MgGroupMemberByRef -GroupId $groupId -DirectoryObjectId $userObjectId
    }

}

# Connect-MgGraph -TenantId $azureConfig.tenantId

$userId = "stemmy.cell@appliedstemcell.com"
$azureUserGroups = Get-AzureUserGroups -UserId $userId
# Write-Output $azureUserGroups
Remove-AzureUserGroups -UserId $userId -Groups $azureUserGroups


