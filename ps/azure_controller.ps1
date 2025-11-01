param(
    [string]$UserId
)

$azureConfig = Get-Content -Path '.\config\azure_config.json' | ConvertFrom-Json

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
        $groupData = Get-MgGroup -GroupId $groupId
        $groupName = $groupData.DisplayName
        #TODO try/catch
        #TODO: Write to log
        # Remove-MgGroupMemberByRef -GroupId $groupId -DirectoryObjectId $userObjectId
    }

}


# $scopes = @(
#     "Chat.ReadWrite.All"
#     "Directory.Read.All"
#     "Group.Read.All"
#     "Mail.ReadWrite"
#     "People.Read.All"
#     "Sites.Manage.All"
#     "User.Read.All"
#     "User.ReadWrite.All",
#     "MailboxSettings.ReadWrite"
# )

# Connect-MgGraph -Scopes $scopes

Connect-MgGraph -TenantId $azureConfig.tenantId -NoWelcome

function Disable-AzureUserAccount{
    param(
        [string]$UserId
    )

    $userLicenses = Get-MgUserLicenseDetail -UserId $UserId
    $licenseSkuIds = @()
    foreach ($license in $userLicenses) {
        $sku = $license.SkuId
        $licenseSkuIds += $sku
    }

    #try/cath
    #will fail if user has no licenses
    Set-MgUserLicense -UserId $UserId -RemoveLicenses $licenseSkuIds -AddLicenses @()
    $params = @{
	    accountEnabled = $false
    }
    Update-MgUser -UserId $UserId -BodyParameter $params

}

#azure controller uses userId email address. Use SamAccountName+"@"+azureConfig.domain
$azureUserGroups = Get-AzureUserGroups -UserId $UserId
# Remove-AzureUserGroups -UserId $UserId -Groups $azureUserGroups
# Disable-AzureUserAccount -UserId $UserId




