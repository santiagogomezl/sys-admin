param(
    [string]$UserId,
    [bool]$OffboardExchangeUser=$false,
    [bool]$Forwarding=$false,
    [string]$ForwardTo
)

$azureConfig = Get-Content -Path '.\config\azure_config.json' | ConvertFrom-Json

Connect-ExchangeOnline -UserPrincipalName $azureConfig.user

#remove mailbox permissions for user
function Remove-ExchangeMailboxPermission{
    param(
        [string]$UserId
    )

    #Get mailboxes user has permissions over. Iterates over all mailboxes
    # Identity: The mailbox in question.
    # User: The security principal (user, security group, Exchange management role group, etc.) that has permission to the mailbox.
    $mailboxes = Get-Mailbox | Get-MailboxPermission -User $UserId

    foreach ($mailbox in $mailboxes) {
        $identity = $mailbox.Identity
        #try/catch
        Remove-MailboxPermission -Identity $identity -User $UserId -AccessRights FullAccess -Confirm:$false
    }
}

#Convert to shared mailbox before removing license
function Convert-ExchangeMailboxToShared{
    param(
        [string]$UserId
    )
    #try/Catch
    Set-Mailbox -Identity $UserId -Type Shared    
}

function Set-ExchangeMailboxForwarding{
        param(
        [string]$UserId,
        [string]$ForwardTo
    )
    #Try/Catch
    Set-Mailbox -Identity $UserId -DeliverToMailboxAndForward $True -ForwardingAddress $ForwardTo
}

if ($OffboardExchangeUser -eq $true -and $UserId -ne ""){
    #$userMailboxData = Get-Mailbox -Identity $UserId
    Remove-ExchangeMailboxPermission -UserId $UserId
    Convert-ExchangeMailboxToShared -UserId $UserId
    if($Forwarding -eq $true -and $ForwardTo -ne ""){
        Set-ExchangeMailboxForwarding -UserId $UserId -ForwardTo $ForwardTo
    }
}

