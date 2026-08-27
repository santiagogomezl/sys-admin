param(
    [string]$UserId,
    [bool]$OffboardExchangeUser=$false,
    [bool]$Forwarding=$false,
    [string]$ForwardTo,
    [bool]$AutoReply = $false,
    [string]$AlternativeContact

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
    # Remove Full Access permissions
    $mailboxes = Get-Mailbox -ResultSize Unlimited | Get-MailboxPermission -User $UserId

    foreach ($mailbox in $mailboxes) {
        $identity = $mailbox.Identity
        Write-Host "Removing FullAccess from $($identity)"
        #try/catch
        Remove-MailboxPermission -Identity $identity -User $UserId -AccessRights FullAccess -Confirm:$false
    }

    #Remove Send As permissions
    $recipients = Get-Recipient -ResultSize Unlimited
    foreach ($recipient in $recipients) {

        $permission = Get-RecipientPermission `
            -Identity $recipient.Guid `
            -Trustee $UserId `
            -ErrorAction SilentlyContinue |
            Where-Object { $_.AccessRights -contains "SendAs" }

        if ($permission) {

            Write-Host "Removing SendAs from $($recipient.PrimarySmtpAddress)"

            Remove-RecipientPermission `
                -Identity $recipient.Guid `
                -Trustee $UserId `
                -AccessRights SendAs `
                -Confirm:$false
        }
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

# Configure automatic reply for former employee
function Set-ExchangeMailboxAutoReply {
    param(
        [string]$UserId,
        [string]$AlternativeContact
    )

    $InternalMessage = @"
This employee is no longer with Applied StemCell.

Please contact $AlternativeContact for assistance.
"@

    $ExternalMessage = @"
Thank you for your email.

This employee is no longer with Applied StemCell.

Please contact $AlternativeContact for assistance.
"@

    Set-MailboxAutoReplyConfiguration `
        -Identity $UserId `
        -AutoReplyState Enabled `
        -InternalMessage $InternalMessage `
        -ExternalMessage $ExternalMessage `
        -ExternalAudience All
}


if ($OffboardExchangeUser -eq $true -and $UserId -ne ""){
    Remove-ExchangeMailboxPermission -UserId $UserId
    Convert-ExchangeMailboxToShared -UserId $UserId
    if($Forwarding -eq $true -and $ForwardTo -ne ""){
        Set-ExchangeMailboxForwarding -UserId $UserId -ForwardTo $ForwardTo
    }

     if ($AutoReply -eq $true -and $AlternativeContact -ne "") {
        Set-ExchangeMailboxAutoReply `
            -UserId $UserId `
            -AlternativeContact $AlternativeContact
    }
}

if ($AutoReply -eq $true -and $AlternativeContact -ne "" -and $UserId -ne "") {
    Set-ExchangeMailboxAutoReply `
        -UserId $UserId `
        -AlternativeContact $AlternativeContact

}

if ($Forwarding -eq $true -and $ForwardTo -ne "" -and $UserId -ne "") {
        Set-ExchangeMailboxForwarding -UserId $UserId -ForwardTo $ForwardTo
}