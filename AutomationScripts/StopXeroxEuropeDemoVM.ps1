    ### Get starting date/time ###
    $StartDate = get-date

    ### Returns strings with status messages ###
    [OutputType([String])] 
 
    ### Connect to Azure and select the subscription to work against ###
    $Cred = Get-AutomationPSCredential -Name "XeroxDemo" 
    $null = Add-AzureRMAccount -Credential $Cred -ErrorAction Stop
    $null = select-azurermsubscription -subscriptionname "Root Subscription"
    
    $output = ""

    
    $RGName = "XeroxEuropeDemo"
    $VMName = "XeroxEuropeDemo"
    Stop-AzureRMVM -ResourceGroupName $RGName -Name $VMName -Force
    $status = (Get-AzureRmVM -ResourceGroupName $RGName -Name $VMName -Status).Statuses
    $status = ($status | Where Code -Like 'PowerState/*')[0].DisplayStatus
    $output = "XeroxEuropeDemo is $status <br/>"


    ### Get Deployment Completion Date ###
    $EndDate = get-date
    
    #Send Deployment Results
    $subject = "Xerox Europe Demo VM Stopped "
    Send-MailMessage -To 'IS@topimagesystems.com' -Subject $subject -Body "Start date: $StartDate <br/> End Date: $EndDate <br/> Output:<br/> $output" -UseSsl -Port 587 -SmtpServer 'smtp.office365.com' -From 'xeroxdemo@topimagesystems.com' -BodyAsHtml -Credential $Cred 