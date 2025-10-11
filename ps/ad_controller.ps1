#Document script

$AD_Config = Get-Content -Path '.\config\ad_config.json' | ConvertFrom-Json

$AD_Creds = New-Object System.Management.Automation.PSCredential(
    $AD_Config.user, 
    (ConvertTo-SecureString $AD_Config.pwd -AsPlainText -Force)
)

$AD_User = "stemmy"

#Get user groups
function Get-UserGroups{
    param(
        [string]$User
    )
    $UserData = Get-ADUser -Identity $User -Properties "MemberOf"
    $UserGroups = $UserData.MemberOf
    return $UserGroups
}

#Remove user from group
function Remove-UserGroups{
    param( 
        [string]$User, 
        [array]$Groups,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    foreach ($Group in $Groups){
        Remove-ADGroupMember -Identity $Group -Members $User -Credential $Credential -Confirm:$false
    }
}

$AD_UserGroups = Get-UserGroups -User $AD_User
Remove-UserGroups -User $AD_User -Groups $AD_UserGroups -Credential $AD_Creds
