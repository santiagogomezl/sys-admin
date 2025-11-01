param(
    [string]$UserId,
    [string]$ForwardTo
)

$azureConfig = Get-Content -Path '.\config\azure_config.json' | ConvertFrom-Json

#Install-Module -Name ExchangeOnlineManagement

# Get-Mailbox | Get-MailboxPermission -User "Heather.Lundie@appliedstemcell.com" | Format-List
#remove mailbox permissions for user
function Remove-ExchangeMailboxPermission{
    param(
        [string]$UserId
    )

    #Get mailboxes user has permissions over
    # Identity: The mailbox in question.
    # User: The security principal (user, security group, Exchange management role group, etc.) that has permission to the mailbox.
    $mailboxes = Get-Mailbox | Get-MailboxPermission -User $UserId

    foreach ($mailbox in $mailboxes) {
        $identity = $mailbox.Identity
        #try/catch
        Remove-MailboxPermission -Identity $identity -User $UserId -AccessRights FullAccess -Confirm:$false
    }

}

function Set-ExchangeMailbox{
    param(
        [string]$UserId,
        [string]$ForwardTo
    )

    Set-Mailbox -Identity $UserId -Type Shared -DeliverToMailboxAndForward $True -ForwardingAddress $ForwardTo
}

Connect-ExchangeOnline -UserPrincipalName $azureConfig.user

# $userMailboxData = Get-Mailbox -Identity $UserId
Remove-ExchangeMailboxPermission -UserId $userId
Set-ExchangeMailbox -UserId $UserId -ForwardTo $ForwardTo
