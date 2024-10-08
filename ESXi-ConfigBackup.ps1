Param
  (
    [parameter(Position=0,Mandatory=$true)]
    [String] $vCenter,
    [parameter(Position=1,Mandatory=$true)]
    [String] $Username,
    [parameter(Position=2,Mandatory=$false)]
    [bool] $FirstRun,
    [parameter(Mandatory=$false)]
    [bool] $ChangePwOrAddUser
  )

#Log file
$LOGFile = "$PSScriptRoot\logs\Backups.log"
#Backup Root Path. If it is an shared drive, make sure that you also have access to it
$BackupRootPath = "E:\vCenter_File-Based_Backup\ESXi-Hosts"
#Number of days before current date
$Days = 14 
#Calculate cutoff date
$ExpiredDate = (Get-Date).AddDays(-$Days)

#Check if First Run
if ($FirstRun){

    #Create EventLog TAG
    If ([System.Diagnostics.EventLog]::SourceExists('SAR') -eq $False) {
        #If Eventlog Logname not exist, create it
        New-EventLog -LogName Application -Source 'SAR'
    }

    #Import VMware PowerCLI Module
    Import-Module -Name VMware.vimAutomation.Core

    #Configure Settings
    Set-PowerCLIConfiguration -Scope AllUser -ParticipateInCEIP $false -Confirm:$false
    Set-PowerCLIConfiguration -Scope AllUser -DefaultVIServerMode single -Confirm:$false 
    Set-PowerCLIConfiguration -Scope AllUser -InvalidCertificateAction Ignore -Confirm:$false  

    #Create new user in VIStore
    New-VICredentialStoreItem -Host $vCenter -User $Username -Password ((get-credential).GetNetworkCredential().password)

    Write-EventLog -LogName Application -Source "SAR" -EventID 1046 -EntryType Information -Message "First Run: All settings configured!"

    #Done
    Write-Host "All necessary settings are configured." -NoNewline -ForegroundColor Green
    Write-Host "Please rerun the script to start the ESXi Config Backup!" -ForegroundColor Green

    exit

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

            Write-EventLog -LogName Application -Source "SAR" -EventID 1049 -EntryType Information -Message "VICredentials: Changed password from: $Username"

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

            Write-EventLog -LogName Application -Source "SAR" -EventID 1050 -EntryType Information -Message "VICredentials: New User added: $Username"

            Write-Host "Added new user to VICredentialsStore: $Username" -ForegroundColor Green

            exit

        }

    }

}

#Check if Backup Log file exist
if (-not (Test-Path $LOGFile)) {

    #Create Backup log file
    New-Item -Path $LOGFile -ItemType File -Force

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
    Get-ChildItem -Path $BackupRootPath -Recurse -File | Where-Object { $_.LastWriteTime -lt $ExpiredDate } | Remove-Item -Force -Verbose

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
