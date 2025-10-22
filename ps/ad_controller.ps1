#Document script
#Todo
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
    $expireindays = $AD_Config.passwordNoticeDays
    Import-Module -Name .\mailer.ps1 -Force
    $DefaultDomainPasswordPolicy = Get-ADDefaultDomainPasswordPolicy
    #DefaultDomainPasswordPolicy.ComplexityEnabled = True
    #https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-addefaultdomainpasswordpolicy?view=windowsserver2025-ps#-complexityenabled

    foreach ($ActiveUser in $ActiveUsers){
        $Name = $ActiveUser.Name
        $emailaddress = $ActiveUser.emailaddress
        $passwordSetDate = $ActiveUser.PasswordLastSet
        # $PasswordPol = (Get-AduserResultantPasswordPolicy -Identity $ActiveUser)
        # # Check for Fine Grained Password
        # if (($PasswordPol) -ne $null)
        # {
        #     $maxPasswordAge = ($PasswordPol).MaxPasswordAge
        # }
        # else
        # {
        #     # No FGP set to Domain Default
        $maxPasswordAge = $DefaultDomainPasswordPolicy.MaxPasswordAge
        # }

        $expireson = $passwordsetdate + $maxPasswordAge
        $today = (get-date)
        $daystoexpire = (New-TimeSpan -Start $today -End $Expireson).Days
        
        # Check Number of Days to Expiry
        $messageDays = $daystoexpire

        if (($messageDays) -gt "1"){
            $messageDays = "in " + "$daystoexpire" + " days."
        }
        else{
            $messageDays = "today."
        }

        # If a user has no email address listed
        if (($emailaddress) -eq $null)
        {
           ##ADD to log
        }# End No Valid Email

        $subject="Your password will expire $messageDays"
        $body ="
        <p> Hi, $($Name)</p>
        <p>Your password will expire $($messageDays)</p>
        <p>Please update your password by logging to <a href='https://myaccount.microsoft.com/?ref=MeControl'>My Account</a></p>
        <p>After you have updated your password, lock your computer and log back in with the new password (You will need to be connected to the office network locally or via VPN connection)</p>
        <p>Please contact your IT Manager if you have any questions or need assistance.</p>  
        <p>Kindly,<br>
        Applied StemCell
        </P>
        "

        if (($daystoexpire -ge 0) -and ($daystoexpire -lt $expireindays)){
            Mailer-SendEmail -EmailAddress $emailaddress -Subject $subject -Body $body
        }

    } 
}

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

$AD_ActiveUsers = Get-ActiveUsers
# Write-Output $AD_ActiveUsers.GetType()
Password-Notice -ActiveUsers $AD_ActiveUsers

# $AD_UserGroups = Get-UserGroups -User $AD_User
# Remove-UserGroups -User $AD_User -Groups $AD_UserGroups -Credential $AD_Creds
