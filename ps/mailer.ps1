
$MailConfig = Get-Content -Path '.\config\mail_config.json' | ConvertFrom-Json

$MailCreds = New-Object System.Management.Automation.PSCredential(
    $MailConfig.user, 
    (ConvertTo-SecureString $MailConfig.pwd -AsPlainText -Force)
)

function Mailer-SendEmail{
    param(
        [string]$EmailAddress,
        [string]$Subject,
        [string]$Body
    )

    # Send-MailMessage -To $EmailAddress -From $MailConfig.user -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $MailConfig.smtpServer -Port $MailConfig.port -UseSSL -Credential $MailCreds
    #Create log
    Send-MailMessage -To $MailConfig.testRecipient -From $MailConfig.user -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $MailConfig.smtpServer -Port $MailConfig.port -UseSSL -Credential $MailCreds
    Write-Output "Sent"
}
        # Send Email Message
            # Send Email Message
            # Send-MailMessage -To $emailaddress -Bcc $testRecipient -From $senderEmail -Subject $subject -Body $body -BodyAsHtml -SmtpServer "smtp.office365.com" -Port 587 -UseSSL -Credential $Cred


        # End Send Message
        # else # Log Non Expiring Password
        # {
        #     $sent = "No"
        #     # If Logging is Enabled Log Details
        #     if (($logging) -eq "Enabled")
        #     {
        #         Add-Content $logfile "$date,$Name,$emailaddress,$daystoExpire,$expireson,$sent"
        #     }
        # }
