param(
    [string]$UserId,
    [bool]$OffboardAzureUser=$false,
    [bool]$GetAzureUserGroups=$false,
    [bool]$RemoveAzureUserGroups=$false,
    [bool]$DisableAzureUserAccount=$false
)

$azureConfig = Get-Content -Path '.\config\azure_config.json' | ConvertFrom-Json

# $azureCreds = New-Object System.Management.Automation.PSCredential(
#     $azureConfig.user, 
#     (ConvertTo-SecureString $azureConfig.pwd -AsPlainText -Force)
# )

# Import-Module Microsoft.Graph

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

function Get-AzureUserGroups{
    param(
        [string]$UserId
    )
    #TODO: handle if user does not exist
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
        #Distribution groups or mail enabled sec groups cannot be removed with Graph API
        if($groupData.MailEnabled -eq $true){
            #Microsoft 365 GroupMailbox
            #Distribution List MailUniversalDistributionGroup
            $recipientTypeDetails = (Get-Recipient -Identity $groupId).RecipientTypeDetails 
        }
        #try/catch
        if (($recipientTypeDetails -eq "GroupMailbox") -or ($groupData.MailEnabled -eq $false)){
            Remove-MgGroupMemberByRef -GroupId $groupId -DirectoryObjectId $userObjectId
        }else{
            Remove-DistributionGroupMember -Identity $groupId -Member $UserId -Confirm:$false
        }
    
        #TODO: Write to log success user $UserId removed from $groupName
        #TODO: Write to log failure 
    }

}

function Disable-AzureUserAccount{
    param(
        [string]$UserId
    )

    $userLicenses = Get-MgUserLicenseDetail -UserId $UserId
    #remove licenses if there are any assigned
    if ($userLicenses){

        $licenseSkuIds = @()
        foreach ($license in $userLicenses) {
            $sku = $license.SkuId
            $licenseSkuIds += $sku
        }

        try{
            #Remove licenses
            Set-MgUserLicense -UserId $UserId -RemoveLicenses $licenseSkuIds -AddLicenses @()
            #TODO: Write to log success 
        }
        catch{
            #TODO: Write to log failure 
        }
    }
    
    #Disable user
    $params = @{
        accountEnabled = $false
    }
    Update-MgUser -UserId $UserId -BodyParameter $params
    #TODO: Write to log success 
}

if ($OffboardAzureUser -eq $true -and $UserId -ne ""){
    #azure controller uses userId email address. Use SamAccountName+"@"+azureConfig.domain
    #Call all functions
    #If user does not exixts. Raise exemption and exit
    $azureUserGroups = Get-AzureUserGroups -UserId $UserId
    #Write to log
    if($azureUserGroups){
        Remove-AzureUserGroups -UserId $UserId -Groups $azureUserGroups
    }
    #Acount would be disabled from AD disable sync
    Disable-AzureUserAccount -UserId $UserId
}

#TODO: Remove Aplipcation access to accounts
#TODO: Backup OneDrive
#TODO: migrate mailbox

# $gId = "cdceb4d8-e770-4f86-a695-fda6c00c5c7d"
# Get-MgGroup -GroupId $gId | Format-List
# (Get-Recipient -Identity $gId).RecipientTypeDetails 

# $gId2 = "76e42277-f620-4f6e-a072-34d2552c62b2"
# Get-MgGroup -GroupId $gId2 | Format-List
# (Get-Recipient -Identity $gId2).RecipientTypeDetails 

# $gId3 = "38c2b8c1-06a7-4b9d-b72d-8e4f8c97afeb"
# Get-MgGroup -GroupId $gId3 | Format-List
# (Get-Recipient -Identity $gId3).RecipientTypeDetails 

