# ESXi-ConfigBackup

This PowerShell script was developed to create configuration backups of ESXi hosts using VMware PowerCLI. The script automatically recognizes older backups so that you always have the latest ``` X ``` days of configurations. This time can be adjusted in the script (Check chapter [Before Starting](#BS)).

Furthermore, the script can be used to run automatically on a daily basis using Microsoft's task scheduler. This ensures that you always have the latest ESXi configuration backups.

The credentials for the ESXi-Host/vCenter is stored in the VICredentialStore so that no passwords need to be set in the script. These access data can also be stored with the script in the VICredentialStore. 

The script has 4 parameters:
```powershell
.\ESXi-BackupConfig.ps1 -Username <vCenter-Admin@vsphere.Local> -vCenter <vcenter.your.domain.tld> -FirstRun $true/$false -ChangePwOrAddUser $true/$false
```

- **!Mandatory! -Username**: The Username which need to loggin to vCenter/ESXi-Host
- **!Mandatory! -vCenter**: vCenter/ESXi-Host Hostname or IP-Adress
- **!Not Mandatory! -FirstRun**: Boolean. this parameter should be set $true at the first start.
- **!Not Mandatory! -ChangePwOrAddUser**: Boolean. If you want to change a password which is stored in VICredentialStore or add a new user to it. Otherwise leave it without this parameters.


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

Testet on vCenter Server version:
- vCenter Server v6.7
- vCenter Server v7.0.3
- vCenter Server v8.0.3

Testet on ESXi version:
- ESXi v6.7
- ESXi v7.0.3
- ESXi v8.0.3

## Usage
### Befor starting
Befor starting, the script should be modified in the following lines:

```powershell
15 #Backup Root Path. If it is an shared drive, make sure that you also have access to it
16 $BackupRootPath = "E:\vCenter_File-Based_Backup\ESXi-Hosts"
17 #Number of days before current date
18 $Days = 14 
```
### First start
When running the script for the first time, it must be started manually as administrator. Open a new PowerShell window as administrator and go to the script path. Then run the following:
```powershell
.\ESXi-BackupConfig.ps1 -Username <vCenter-Admin@vsphere.Local> -vCenter <vcenter.your.domain.tld> -FirstRun $true
```
Instead of the Hostname you can also type in the IP-Adress. The ```-Username``` and ```-vCenter``` is mandatory! Furthermore, the parameter ```-FirstRun``` must be set to ```$true```. If you have no vCenter, you can also use the ESXi-Host IP-Adress/Hostname. 

After starting the script for the first time, the following PowerCLI configurations are set:

- ParticipateInCEIP = False
- DefaultVIServerMode = single
- InvalidCertificateAction = Ignore (If you do not want to ignore the certificate and you have a valid one, you can set this to "Warn". Check the script at line 37)
- The user you have logged in with will be added to the VICredentialStore so that you no longer need a password to run the script. 

After settings has been configured, the script is closed without running a backup.

### Manually start
As soon as the first start has been performed, the script can be started directly from a powershell console without entering the password: 
```powershell
.\ESXi-BackupConfig.ps1 -Username <vCenter-Admin@vsphere.Local> -vCenter <vcenter.your.domain.tld>
```
It is recommended that you create a task via Microsoft task schedule and save it automatically every day. See next chapter.

### Auto start
To start the script daily using Microsoft task scheduler, a task should be created that runs as ```nt authority\system```.

However, the script must be executed again with the parameter ```-FirstRun $true``` as ```nt authority\system``` so that all PowerCLI settings for the ```nt authority\system``` are also set. To achive this, you must download and extract [PSTools](https://learn.microsoft.com/en-us/sysinternals/downloads/psexec). 

Open Command Prompt as an administrator, browse to where you extracted the PSTools to and run the following command:

```powershell
.\Psexec -i -s C:\WINDOWS\system32\WindowsPowerShell\v1.0\powershell.exe
```
If you now type in ```whoami``` you will see, tha you are:
```powershell
nt authority\system
```
Now you just need to repeat steps from [First start](#FirstStart).

### Change Passwort or add User
If the password needs to be changed, the parameter ```-ChangePwOrAddUser``` must also be set to ```$true```: 
```powershell
.\ESXi-BackupConfig.ps1 -Username <vCenter-Admin@vsphere.Local> -vCenter <vcenter.your.domain.tld> -ChangePwOrAddUser $true
```
The user's password is only changed if it previously existed in the VICredenetialStore. If the user does not exist, a new user is created. After the user has been changed or added, the script is closed without running a backup.

If you want to remove all users from the VICredentialStore, open a PowerShell Console as admin and execute the following command:
```powershell
Remove-VICredentialStoreItem *
```
You will then be asked to delete the user individually. 

## Logging
In addition to the log file that is created in the logs directory with the name **Backups.log**, logging is also carried out in the EventLog -> Applications.
An event log TAG with the name SAR is created for this purpose when the script is started for the first time. The following IDs are documented:
ID | Meaning 
-------- | -------- 
1046   | First Run: All settings configured
1047   | ESXi Config Backup sucessfull
1048   | Error: See Exception Message
1049   | VICredentials: Changed password from: $Username
1050   | VICredentials: New User added: $Username

## Authors

- [@Aliko47](https://github.com/Aliko47)

