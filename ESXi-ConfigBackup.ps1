Param
  (
    [parameter(Position=0,Mandatory=$true)]
    [String] $vCenter,
    [parameter(Position=1,Mandatory=$true)]
    [String] $Username,
    [parameter(Position=2,Mandatory=$false)]
    [bool] $ChangePwOrAddUser
  )

#First-Run Log File
$FirstRun = "$PSScriptRoot\logs\FirstRun.log"
#Log file
$LOGFile = "$PSScriptRoot\logs\Backups.log"
#Root Path
$BackupRootPath = "$PSScriptRoot\ESXi-Hosts"
#Number of days before current date
$Days = 14 
#Calculate cutoff date
$ExpiredDate = (Get-Date).AddDays(-$Days)

#Create EventLog TAG
If ([System.Diagnostics.EventLog]::SourceExists('SAR') -eq $False) {
    #If Eventlog Logname not exist, create it
    New-EventLog -LogName Application -Source 'SAR'
}

#Check if First Run
if (-not (Test-Path $FirstRun)) {

    #Create Backup log file
    New-Item -Path $LOGFile -ItemType File -Force

    #Import VMware PowerCLI Module
    Import-Module -Name VMware.vimAutomation.Core

    #Configure Settings
    Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false
    Set-PowerCLIConfiguration -DefaultVIServerMode single -Confirm:$false 
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false  

    #Create new user in VIStore
    New-VICredentialStoreItem -Host $vCenter -User $Username -Password ((get-credential).GetNetworkCredential().password)

    #Done
    Write-Host "All necessary settings are configured." -NoNewline -ForegroundColor Green
    Write-Host "Please rerun the script to start the ESXi Config Backup!" -ForegroundColor Green

    #Create First Run log file
    New-Item -Path $FirstRun -ItemType File -Force
    Add-Content -Path $FirstRun -Value "--------------------!First run!---------------------------------------------------------------"
    Add-Content -Path $FirstRun -Value (Get-Date -Format "dddd dd/MM/yyyy HH:mm")
    Add-Content -Path $FirstRun -Value "Do not remove this file! Except, you know what you are doing!"
    Add-Content -Path $FirstRun -Value "----------------------------------------------------------------------------------------------"

    exit

}

#Check if Backup Log file exist
if (-not (Test-Path $LOGFile)) {
    
    #Create Backup log file
    New-Item -Path $LOGFile -ItemType File -Force

}

if ($ChangePwOrAddUser) {

    #Import VMware PowerCLI Module
    Import-Module -Name VMware.vimAutomation.Core

    [string[]]$GetAllUsers = Get-VICredentialStoreItem | select User 


    for($i=0;$i -lt $GetAllUsers.Length ;$i++) {

        $GetAllUsers[$i] = $GetAllUsers[$i].TrimStart("@{User=").TrimEnd("}").ToLower()

        if ($Username.ToLower() -eq $GetAllUsers[$i]) {
        
            #Change VICredentials 
            New-VICredentialStoreItem -Host $vCenter -User $Username -Password ((get-credential).GetNetworkCredential().password)
            
            #Fill the log file
            Add-Content -Path $LOGFile -Value ""
            Add-Content -Path $LOGFile -Value "--------------------!Changed Password!--------------------------------------------------------"
            Add-Content -Path $LOGFile -Value (Get-Date -Format "dddd dd/MM/yyyy HH:mm")
            Add-Content -Path $LOGFile -Value "Username: $Username"
            Add-Content -Path $LOGFile -Value "----------------------------------------------------------------------------------------------"

            Write-EventLog -LogName Application -Source "SAR" -EventID 1048 -EntryType Information -Message "VICredentials: Changed password from: $Username"

            Write-Host "Password for $Username changed!" -ForegroundColor Green

            exit

        }
        else {

            #Add new VICredentials 
            New-VICredentialStoreItem -Host $vCenter -User $Username -Password ((get-credential).GetNetworkCredential().password)
            
            #Fill the log file
            Add-Content -Path $LOGFile -Value ""
            Add-Content -Path $LOGFile -Value "--------------------!New User added!----------------------------------------------------------"
            Add-Content -Path $LOGFile -Value (Get-Date -Format "dddd dd/MM/yyyy HH:mm")
            Add-Content -Path $LOGFile -Value "Username: $Username"
            Add-Content -Path $LOGFile -Value "----------------------------------------------------------------------------------------------"

            Write-EventLog -LogName Application -Source "SAR" -EventID 1049 -EntryType Information -Message "VICredentials: New User added: $Username"

            Write-Host "Added new user to VICredentialsStore: $Username" -ForegroundColor Green

            exit

        }

    }

}

try {

    #Backup Path
    $BackupPath = New-Item -ItemType Directory -Path "$BackupRootPath\$((Get-Date).ToString('MM.dd.yyyy-HH.mm.ss'))"

    #Import VMware PowerCLI Module
    Import-Module -Name VMware.vimAutomation.Core

    #Connect to vCenter
    Connect-VIServer -Server $vCenter

    #Backup all Hosts Config
    Get-VMhost | Get-VMHostFirmware -BackupConfiguration -DestinationPath $BackupPath

    #Get All Files modified more than the last "$Days" days
    Get-ChildItem -Path $BackupRootPath -Recurse -File | Where-Object { $_.LastWriteTime -lt $ExpiredDate } | Remove-Item –Force -Verbose

    #Fill the log file
    Add-Content -Path $LOGFile -Value ""
    Add-Content -Path $LOGFile -Value "--------------------!Successfull!-------------------------------------------------------------"
    Add-Content -Path $LOGFile -Value (Get-Date -Format "dddd dd/MM/yyyy HH:mm")
    Add-Content -Path $LOGFile -Value "----------------------------------------------------------------------------------------------"

    Write-EventLog -LogName Application -Source "SAR" -EventID 1047 -EntryType Information -Message "ESXi Config Backup done!"
        
}
catch {

    #Fill the log file with the Exception Message
    Add-Content -Path $LOGFile -Value ""
    Add-Content -Path $LOGFile -Value "-----------------------!ERROR!----------------------------------------------------------------"
    Add-Content -Path $LOGFile -Value (Get-Date -Format "dddd dd/MM/yyyy HH:mm")
    Add-Content -Path $LOGFile -Value $_.Exception.Message
    Add-Content -Path $LOGFile -Value "----------------------------------------------------------------------------------------------"

    Write-EventLog -LogName Application -Source "SAR" -EventID 1048 -EntryType Error -Message $_.Exception.Message
        
}
