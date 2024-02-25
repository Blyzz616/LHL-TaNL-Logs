# Workflow:

## Purpose:

The purpose of this presentation is to explain the processes and steps taken in monitoring the log files from the two live web servers in order to identify any problems and/or any indicators of attack.

### What is monitored:

There are 2 production web servers on the network that are publicly available and for the purpose of assisting the youth in a range of rural communities to seek employment.

- Internet Information Services (IIS) version 10.0.20348.1, running on a Windows Server 2022
- Apache/2.4.41, Running on Ubuntu 20.04.6 LTS

The log files for both of these web servers are being monitored for any unusual activity. This includes:
- Unusual Failed logins
- High number of failed logins
- Logins occurring outside of the expected times
- Failed page requests (404s)

### When does monitoring occur:

While there are specific times that are of interest to the core function of Turn a New Leaf, the servers are monitored on a continual basis, 24 hours a day, 7 days a week.

The times of particular interest are:
- 	Friday midnight (00:00AM) to Wednesday Midnight (11:59PM)
  - All login-attempts are of concern
- Thursday (00:00AM – 11:59PM) – failed logs
- Thursday – failed logs with constant time between them (build logic) (2)
- Thursday – excessive failed logins in short time (2)

## Programming:

In the course of setting up the monitoring of the web server logs for Turn a New Leaf, three different operating systems were used. The main Operating system for monitoring all of the log files is Kali Linux. The 2 web servers are running Windows Server 2022 on one and Ubuntu 20.04.6 LTS on the other

### Windows

Programming on the Windows web server was required to send the logs through to the Kali-Linux Log server. This was accomplished using Windows PowerShell and that script is being implemented on an on-going basis by Windows Task Scheduler.

### Ubuntu

Programming on the Ubuntu web server was conducted using SublimeText3 IDE and using the BASH scripting language. The script is run by default each time the server powers on by using Crontab.

### Kali-Linux

Similar to the Ubuntu web server, the programming was completed on SublimeText3 IDE and run using the BASH scripting language.

## Expected output

All of the server web logs are sent to the Kali Linux log server for processing. The logs from the Windows server and the Ubuntu server are processed separately, each by its own script. This is necessary because the two servers produce different types of logs, each with its own syntax.

The output for both of the scripts is identical however, saving the human-readable information in the following structure:

### For page-not-found errors:

/home/user/logMonitor/404/\<ip address\>/\<date\>.log
This breaks down the logs into directories based on the incoming IP and then further down into individual files based on the date of the incoming request. Each log fill will keep the record of each page request and the first line at the top of each file will have the total number of page requests for that day.

example of /home/user/logMonitor/404/172.16.14.3/2024-02-24.log
```
    1
    Failed Page: /admin-login.php
    From IP address: 172.16.14.3
    Time: 19:35:12
    Date: Feb 24, 2024 – Sat
    Useragent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36
```

### For failed login attempts:

/home/logMonitor/401/\<ip addres\>/\<date\>.log
As with the page-not-found errors, these events will be saved in a similar fashion. However, with these logs we also keep a record of the time difference between the failed login events. If there are more than 5 failed login events from any specific address on a day, an email is generated containing the relevant details of the failed login events.

example of /home/user/logMonitor/401/172.16.14.3/2024-02-24.log
```
    3
    Time since last fail: 15
    From IP address: 172.16.14.3
    Time: 12:13:25
    Date: Feb 24, 2024 – Sat
    Useragent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36
```

Example of generated email: 
```
From: LogServer <kali@turnanewleaf.ca>
To: Jim Sher <jim@turnanewleaf.ca>
Cc:
Subject: Suspicious Failed Logins
Data:
There were more than 5 failed login attempts from 172.16.14.3 on Feb 24, 2024, starting at 12:13:25. Please investigate and escalate if required.
```

## Documentation

Setting up the servers to send their logs to the Log server required different configuration as one server is Microsoft IIS and the other is Apache.

### Settging up the log forwarding on Windows Server 2022 for ISS

A script was created in PowerShell. This is linked [here](send_iis_logs.ps1). Once the script was saved, We need to ensure that it is contantly run in the background each time the server starts. To do this we Create a new Task in Windows Task Scheduler with the following properties:
- Description: Send IIS logs to log server
- Start: When the computer starts
- Action: Start a program
- Program/Script: C:\Users\Administrator\send_iis_logs.ps1
- Arguments: -ExecutionPolicy Bypass -File “C:\Users\Administrator\send_iis_logs.ps1”
- Run: At startup, whether user is logged on or not and with highest privileges





Each time a new event is recorded, a record is kept in a specific location.
•	Potential output for:
o	Brute force on Thursday ( add why)
o	Failed logins outside of Thursday ( add why)
o	Number of failed logins per IP address ( add why)
o	Attempted access to non-existent pages ( add why)
o	List of Ips that successfully logged in
Documentation
•	Where will I save the raw data and how will I process it for escalation to management
Unusual behaviour
•	What is unusual – why is it a concern
Potential Iterations
•	Add monitoring for bandwidth usage to monitor potential data exfiltration

•	Recommned disableing the login page after thurdays
•	Recommend Geo-IP lookup to prevent anyone outside of canaad accessing the page





New Task Created in Task Scheduler with the following attributes:
Name: SendIISLogs
Description: Send IIS logs to log server
Start: When the computer starts
Action: Start a program
Program/Script: C:\Users\Administrator\SendIISLogs.ps1
Arguments: -ExecutionPolicy Bypass -File “C:\Users\Administrator\SendIISLogs.ps1”
Run: At startup, whether user is logged on or not and with highest privileges




Service set up on Linux Web server to forward logs to Log Server
rsyslog installed on server and config file at /etc/rsyslog.conf edited to include the following:
module(load="imfile" PollingInterval="10" statefile.directory="/var/spool/rsyslog")
input(type="imfile" File="/var/log/apache2/*.log" Tag="apache_logs" Severity="info" Facility="local1")
local1.* @172.16.14.51:514


This service runs continually and will forward all logs to the log server

