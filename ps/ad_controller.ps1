#Document script
#Todo
#Moditi Get-ActiveUsers. Currently only getting users with passwordneverexpires
##Add argv with username 

$AD_Config = Get-Content -Path '.\config\ad_config.json' | ConvertFrom-Json

$AD_Creds = New-Object System.Management.Automation.PSCredential(
    $AD_Config.user, 
    (ConvertTo-SecureString $AD_Config.pwd -AsPlainText -Force)
)

$AD_User = "stemmy"

# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired
function Get-ActiveUsers{
    $ActiveUsers = Get-ADUser -Filter * -Properties "Name", "PasswordNeverExpires", "PasswordExpired", "PasswordLastSet", "EmailAddress" |where {$_.Enabled -eq "True"} | where { $_.PasswordNeverExpires -eq $false } | where { $_.passwordexpired -eq $false }
    return $ActiveUsers
}

function Password-Notice{
    param(
        [array]$ActiveUsers
    )
    $expireInDays = $AD_Config.passwordNoticeDays
    Import-Module -Name .\mailer.ps1 -Force
    $defaultDomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy
    #DefaultDomainPasswordPolicy.ComplexityEnabled = True
    #https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-addefaultdomainpasswordpolicy?view=windowsserver2025-ps#-complexityenabled

    foreach ($activeUser in $ActiveUsers){
        $name = $activeUser.Name
        $emailAddress = $activeUser.emailaddress
        $passwordSetDate = $activeUser.PasswordLastSet
        # $PasswordPol = (Get-AduserResultantPasswordPolicy -Identity $ActiveUser)
        # # Check for Fine Grained Password
        # if (($PasswordPol) -ne $null)
        # {
        #     $maxPasswordAge = ($PasswordPol).MaxPasswordAge
        # }
        # else
        # {
        #     # No FGP set to Domain Default
        $maxPasswordAge = $defaultDomainPasswordPolicy.MaxPasswordAge
        # }

        $expiresOn = $passwordSetDate + $maxPasswordAge
        $today = (get-date)
        $daysToExpire = (New-TimeSpan -Start $today -End $expiresOn).Days
        
        # Check Number of Days to Expiry
        $messageDays = $daysToExpire

        if (($messageDays) -gt "1"){
            $messageDays = "in " + "$daysToExpire" + " days."
        }
        else{
            $messageDays = "today."
        }

        # If a user has no email address listed
        # if ($emailAddress -eq $null)
        if ($emailAddress -eq "")
        {
           ##ADD to log
        }# End No Valid Email

        $subject="Your password will expire $messageDays"
        $body ="
        <p> Hi, $($name)</p>
        <p>Your password will expire $($messageDays)</p>
        <p>Please update your password by logging to <a href='https://myaccount.microsoft.com/?ref=MeControl'>My Account</a></p>
        <p>After you have updated your password, lock your computer and log back in with the new password (You will need to be connected to the office network locally or via VPN connection)</p>
        <p>Please contact your IT Manager if you have any questions or need assistance.</p>  
        <p>Kindly,<br>
        Applied StemCell
        </P>
        "

        if (($daysToExpire -ge 0) -and ($daysToExpire -lt $expireInDays)){
            Mailer-SendEmail -EmailAddress $emailAddress -Subject $subject -Body $body
        }

    } 
}

#Get user groups
function Get-UserGroups{
    param(
        [string]$User
    )
    $userData = Get-ADUser -Identity $User -Properties "MemberOf"
    $userGroups = $userData.MemberOf
    return $userGroups
}

#Remove user from group
function Remove-UserGroups{
    param( 
        [string]$User, 
        [array]$Groups,
        [System.Management.Automation.PSCredential]$Credential
    )
    
    foreach ($group in $Groups){
        Remove-ADGroupMember -Identity $group -Members $User -Credential $Credential -Confirm:$false
    }
}

#$AD_ActiveUsers = Get-ActiveUsers
# Write-Output $AD_ActiveUsers.GetType()
#Password-Notice -ActiveUsers $AD_ActiveUsers

# $AD_UserGroups = Get-UserGroups -User $AD_User
# Remove-UserGroups -User $AD_User -Groups $AD_UserGroups -Credential $AD_Creds

