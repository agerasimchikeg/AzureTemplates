    ### Get starting date/time ###
    $StartDate = get-date

    ### Returns strings with status messages ###
    [OutputType([String])] 
 
    ### Connect to Azure and select the subscription to work against ###
    $Cred = Get-AutomationPSCredential -Name "XeroxDemo" 
    $null = Add-AzureRMAccount -Credential $Cred -ErrorAction Stop
    $null = select-azurermsubscription -subscriptionname "Root Subscription"
    
    ### Stop the running VM ###
    get-azurermvm -resourcegroupname xeroxdemo -Name XeroxGI | stop-azurermvm -force

    ### Define variables for script execution ###
    $storageRGName="xeroxdemo"
    $RGName="XeroxDemo"
    $locName="Central US"

    ### Save the destination storage account key ###
    $StorageKey = (Get-AzureRmStorageAccountKey -Name "xeroxdemo" -ResourceGroupName $storageRGName ).key1

    ### Set the Source VHD (South Central US) - authenticated container ###
    $srcUri = "https://xeroxdemo.blob.core.windows.net/vhds/XeroxDemo.vhd" 

    ### Set the Source Storage Account (South Central US) ###
    $StorageAccount = "xeroxdemo"
  
    ### Create the storage account context ### 
    $storageContext = New-AzureStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $StorageKey  
 
    ### Destination Container Name ### 
    $containerName = "copiedvhds"
 
    ### Start the asynchronous VHD copy - specify the source authentication with -SrcContext ### 
    $blob1 = Start-AzureStorageBlobCopy -srcUri $srcUri -SrcContext $storageContext -DestContainer $containerName -DestBlob "XeroxDemo.vhd" -DestContext $storageContext -Force

    ### Retrieve the current status of the copy operation ###
    $status = $blob1 | Get-AzureStorageBlobCopyState 
 
    ### Loop until complete ###                                    
    While($status.Status -eq "Pending"){
        $status = $blob1 | Get-AzureStorageBlobCopyState 
        Start-Sleep 10
    }

    ### Get Deployment Completion Date ###
    $EndDate = get-date
    
    #Send Deployment Results
    $subject = "XeroxDemo VHD Update"
    Send-MailMessage -To 'IS@topimagesystems.com' -Subject $subject -Body "Start date: $StartDate <br/> End Date: $EndDate <br/> Output: Xerox Demo VHDs have been updated successfully." -UseSsl -Port 587 -SmtpServer 'smtp.office365.com' -From 'xeroxdemo@topimagesystems.com' -BodyAsHtml -Credential $Cred

    ### Stop the running VM ###
    get-azurermvm -resourcegroupname xeroxdemo -Name XeroxGI | start-azurermvm