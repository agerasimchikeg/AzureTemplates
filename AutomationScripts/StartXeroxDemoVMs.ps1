    ### Get starting date/time ###
    $StartDate = get-date

    ### Returns strings with status messages ###
    [OutputType([String])] 
 
    ### Connect to Azure and select the subscription to work against ###
    $Cred = Get-AutomationPSCredential -Name "XeroxDemo" 
    $null = Add-AzureRMAccount -Credential $Cred -ErrorAction Stop
    $null = select-azurermsubscription -subscriptionname "Root Subscription"
    
    $output = ""

    For ($i=1; $i -lt 4;$i++){
        $RGName = "XeroxDemo$i"
        $VMName = "XeroxDemo$i"
        Start-AzureRMVM -ResourceGroupName $RGName -Name $VMName
        $status = (Get-AzureRmVM -ResourceGroupName $RGName -Name $VMName -Status).Statuses
        $status = ($status | Where Code -Like 'PowerState/*')[0].DisplayStatus
        $output += "XeroxDemo$i is $status <br/>"
    }
   

    ### Get Deployment Completion Date ###
    $EndDate = get-date
    
    #Send Deployment Results
    $subject = "Xerox Demo VMs Started"
    Send-MailMessage -To 'IS@topimagesystems.com' -Subject $subject -Body "Start date: $StartDate <br/> End Date: $EndDate <br/> Output: <br/> $output" -UseSsl -Port 587 -SmtpServer 'smtp.office365.com' -From 'xeroxdemo@topimagesystems.com' -BodyAsHtml -Credential $Cred 