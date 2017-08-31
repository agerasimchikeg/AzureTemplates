    ### Get starting date/time ###
    $StartDate = get-date

    ### Returns strings with status messages ###
    [OutputType([String])] 
 
    ### Connect to Azure and select the subscription to work against ###
    $Cred = Get-AutomationPSCredential -Name "XeroxDemo" 
    $null = Add-AzureRMAccount -Credential $Cred -ErrorAction Stop
    $null = select-azurermsubscription -subscriptionname "Root Subscription"
    
    ### Define variables for script execution ###
    $deployname="XeroxEuropeDemo"
    $storageRGName="XeroxEuropeDemoStore"
    $RGName="XeroxEuropeDemo"
    $locName="West Europe"
    $templateURI="https://raw.githubusercontent.com/egistics/AzureTemplates/master/ConfigurationTemplates/XeroxEuropeDemo.json"

    ### Deleting Resource Group ###
    Remove-AzureRMResourceGroup -Name $RGName -Force

    ### Save the destination storage account key ###
    $destStorageKey = (Get-AzureRmStorageAccountKey -Name "xeroxeuropedemossd" -ResourceGroupName $storageRGName ).key1

    ### Set the Source VHD (South Central US) - authenticated container ###
    $srcUri = "https://xeroxdemo.blob.core.windows.net/copiedvhds/XeroxDemo.vhd" 

    ### Set the Source Storage Account (South Central US) ###
    $srcStorageAccount = "xeroxdemo"
    $srcStorageKey = "1axUsYnVCYNF5L3ayboEaudEVr4z+NyjbhpcVDI63dXGHMiS2bfI2ZNyJVPsrqsXBKG18JkkR0uKNf0EMkPNBg=="
 
    ### Set the destination Storage Account (South Central US) ###
    $destStorageAccount = "xeroxeuropedemossd"
 
    ### Create the source storage account context ### 
    $srcContext = New-AzureStorageContext -StorageAccountName $srcStorageAccount -StorageAccountKey $srcStorageKey  
 
    ### Create the destination storage account context ### 
    $destContext = New-AzureStorageContext -StorageAccountName $destStorageAccount -StorageAccountKey $destStorageKey  
 
    ### Destination Container Name ### 
    $containerName = "vhds"

    ### Remove Dest Storage Container ###
    Remove-AzureStorageContainer -Name $containerName -Context $destContext -Force
    
    ### Insert post-deletion delay before confirming storage container has been deleted ###
    Start-Sleep 60
    while (Get-AzureStorageContainer -Context $destContext | Where-Object { $_.Name -eq $containerName })
    {
        Start-Sleep 10
    }

    ### Create the container on the destination ### 
    New-AzureStorageContainer -Name $containerName -Context $destContext 
 
    ### Start the asynchronous VHD copy - specify the source authentication with -SrcContext ### 
    $blob1 = Start-AzureStorageBlobCopy -srcUri $srcUri -SrcContext $srcContext -DestContainer $containerName -DestBlob "XeroxDemo.vhd" -DestContext $destContext

    ### Retrieve the current status of the copy operation ###
    $status = $blob1 | Get-AzureStorageBlobCopyState 
 
    ### Loop until complete ###                                    
    While($status.Status -eq "Pending"){
        $status = $blob1 | Get-AzureStorageBlobCopyState 
        Start-Sleep 10
    }

    ###  Creating Resource Group ###
    New-AzureRMResourceGroup -Name $RGName -Location $locName
    $deploymentOutput = (New-AzureRMResourceGroupDeployment -Name $deployName -ResourceGroupName $RGName -TemplateUri $templateURI).ProvisioningState

    ### Get Deployment Completion Date ###
    $EndDate = get-date
    
    #Send Deployment Results
    $subject = "XeroxEuropeDemo Deployment Results"
    $body = "Deployment Completed Successfully."
    Send-MailMessage -To 'IS@topimagesystems.com' -Subject $subject -Body "Start date: $StartDate <br/> End Date: $EndDate <br/> Output: $deploymentOutput" -UseSsl -Port 587 -SmtpServer 'smtp.office365.com' -From 'xeroxdemo@topimagesystems.com' -BodyAsHtml -Credential $Cred 