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
        try{
            $recipientTypeDetails = (Get-Recipient -Identity $groupId).RecipientTypeDetails 
            if ($recipientTypeDetails -eq "GroupMailbox"){
                #Microsoft 365
                Remove-MgGroupMemberByRef -GroupId $groupId -DirectoryObjectId $userObjectId
            }else{
                #Distribution List
                Remove-DistributionGroupMember -Identity $groupId -Member $UserId -Confirm:$false
            }
        }
            #TODO: Write to log success user $UserId removed from $groupName
        catch{
            #TODO: Write to log failure 
        }    
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
    Disable-AzureUserAccount -UserId $UserId
}

#TODO: Remove APplication access to accounts


