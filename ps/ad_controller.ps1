#Document script
#Todo
#Moditi Get-ActiveUsers. Currently only getting users with passwordneverexpires
##Add argv with username 

$adConfig = Get-Content -Path '.\config\ad_config.json' | ConvertFrom-Json

$adCreds = New-Object System.Management.Automation.PSCredential(
    $adConfig.user, 
    (ConvertTo-SecureString $adConfig.pwd -AsPlainText -Force)
)

# Get Users From AD who are Enabled, Passwords Expire and are Not Currently Expired
function Get-ActiveUsers{
    $ActiveUsers = Get-ADUser -Filter * -Properties "Name", "PasswordNeverExpires", "PasswordExpired", "PasswordLastSet", "EmailAddress" |where {$_.Enabled -eq "True"} | where { $_.PasswordNeverExpires -eq $false } | where { $_.passwordexpired -eq $false }
    return $ActiveUsers
}

function Password-Notice{
    param(
        [array]$ActiveUsers
    )
    $expireInDays = $adConfig.passwordNoticeDays
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

#Get-UserData
function Get-UserData{
    param(
        [string]$User
    )
    $userData = Get-ADUser -Identity $User -Properties *
    return $userData
}

#Remove user from group
function Remove-UserGroups{
    param( 
        [object]$UserData, 
        [System.Management.Automation.PSCredential]$Credential
    )

    $userSAM= $UserData.SamAccountName
    $userGroups = $UserData.MemberOf
    
    foreach ($group in $userGroups){
        Remove-ADGroupMember -Identity $group -Members $userSAM -Credential $Credential -Confirm:$false
    }
}

#Disbale user and move to "Former Employees"
##Add Notes: Disable on $Date by "AD Controller"

function Disable-UserAccount{
    param(
        [object]$UserData,
        [System.Management.Automation.PSCredential]$Credential
    )
    ##try/catch
    ##add login

    $userSAM= $UserData.SamAccountName
    $userDN = $UserData.DistinguishedName
    $date = Get-Date -Format "MM/dd/yyyy"

    Disable-ADAccount -Identity $userSAM -Credential $Credential
    Set-ADUser -Identity $userSAM -Replace @{Description="Account disabled on $date by AD Controller"} -Credential $Credential
    Move-ADObject -Identity $userDN -TargetPath $adConfig.formerDN -Credential $Credential
}

#AD Controller uses SamAccountName
$userData = Get-UserData -User "stemmy"
Remove-UserGroups -UserData $userData -Credential $adCreds
Disable-UserAccount -UserData $userData -Credential $adCreds

#$AD_ActiveUsers = Get-ActiveUsers
# Write-Output $AD_ActiveUsers.GetType()
#Password-Notice -ActiveUsers $AD_ActiveUsers
