# ESXi-ConfigBackup

This PowerShell script was developed to create configuration backups of ESXi hosts using VMware PowerCLI. The script automatically recognizes older backups so that you always have the latest ``` X ``` days of configurations. This time can be adjusted in the script.

Furthermore, the script can be used to run automatically on a daily basis using Microsoft's task scheduler. This ensures that you always have the latest ESXi configuration backups.

The credentials for the ESXi-Host/vCenter is stored in the VICredentialStore so that no passwords need to be set in the script. These access data can also be stored with the script in the VICredentialStore. 

The script has 3 parameters:
```powershell
.\ESXi-BackupConfig.ps1 -Username <vCenter-Admin@vsphere.Local> -vCenter <vcenter.your.domain.tld> -ChangePwOrAddUser $true/$false
```

- **Mandatory** Username: The Username which need to loggin to vCenter/ESXi-Host
- **Mandatory** vCenter: vCenter/ESXi-Host Hostname or IP-Adress
- **Not Mandatory** ChangePwOrAddUser: Boolean. If you want to change a password which is stored in VICredentialStore or add a new user to it. Otherwise leave it without this parameters.


## Requirements

Before the script can be used, PowerCLI must be installed:

```powershell
Install-Module -Name VMware.PowerCLI
```
It is recommended that you always keep PowerCLI up to date: 
```powershell
Update-Module -Name VMware.PowerCLI
```
The script was tested on the following operating systems: 
- Windows 10 
- Windows Server 2016
- Windows Server 2019
- Windows Server 2022

Testet on PowerShell Version: 
- 5.1 Build 14393 Revision 7254
- 5.1 Build 20348 Revision 2652
## Usage
### Befor starting
Befor starting, the script should be modified in the following lines:

```powershell
15 #Root Path
16 $BackupRootPath = "E:\vCenter_File-Based_Backup\ESXi-Hosts" #Set your Backup Path
17 #Number of days before current date
18 $Days = 14 #how many backups of the last few days should be kept?
```
### First start
When running the script for the first time, it must be started manually as administrator. Open a new PowerShell window as administrator and go to the script path. Then run the following:
```powershell
.\ESXi-BackupConfig.ps1 -Username <vCenter-Admin@vsphere.Local> -vCenter <vcenter.your.domain.tld>
```
Instead of the Hostname you can also type in the IP-Adress. The ```-Username``` and ```-vCenter``` is mandatory! If you have no vCenter, you can also use the ESXi-Host IP-Adress/Hostname. 

After Starting starting for the first time the script, a log file **FirstRun.log** is created in the same PSRootPath\logs. Do not remove this file! At the first start the following PowerCLI configurations are set at:

- ParticipateInCEIP = False
- DefaultVIServerMode = single
- InvalidCertificateAction = Ignore (If you do now want to ignore the certificate and you have a valid one, you can set this to "Warn". Check the script at line 40)

### Manually start
From now on, the script can be started directly from a powershell console without entering the password: 
```powershell
.\ESXi-BackupConfig.ps1 -Username <vCenter-Admin@vsphere.Local> -vCenter <vcenter.your.domain.tld>
```
It is recommended that you create a task via Microsoft task schedule and save it automatically every day. See next chapter.

### Auto start
To start the script daily using Microsoft task scheduler, a task should be created that runs as ```nt authority\system```.

However, the log **FirstStart.log** must first be removed first and the script must be executed again as ```nt authority\system``` so that all PowerCLI settings for the ```nt authority\system``` are also set. To achive this, you must download and extract [PSTools](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec). 

Open Command Prompt as an administrator, browse to where you extracted the PSTools to and run the following command:

```powershell
.\Psexec -i -s C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe
```
If you now type in ```whoami``` you will see, tha you are:
```powershell
nt authority\system
```
Now you just need to repeat steps from [First start](https://github.com/Aliko47/ESXi-ConfigBackup/tree/main?tab=readme-ov-file#first-start-firststart)

### Change Passwort or add User
...
## Logging
...
## Authors

- [@Aliko47](https://github.com/Aliko47)

