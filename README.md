# Table of Contents

- [Executive Summary](#executive-summary)
- [Workflow](#workflow)
- [Purpose](#purpose)
  - [What is monitored](#what-is-monitored)
  - [When does mnonitoring occur](#when-does-monitoring-occur)
- [Programming](#programming)
  - [Windows](#windows)
  - [Ubuntu](#ubuntu)
  - [Kali-Linux](#kali-linux)
- [Expected output](#expected-output)
  - [For page-not-found errors](#for-page-not-found-errors)
  - [For failed login attempts](#for-failed-login-attempts)
- [Documentation](#documentation)
  - [Setting up the log forwarding on Windows Server 2022 for ISS](#setting-up-the-log-forwarding-on-windows-server-2022-for-iss)
  - [Setting up the log forwarding on Ubuntu 20.04.6 LTS for Apache2](#setting-up-the-log-forwarding-on-ubuntu-20.04.6-lts-for-apache2)
  - [Setting up the Log Server on Kali-Linux](#setting-up-the-log-server-on-kali-linux)
  - [Log File Processing](#log-file-processing)
  - [Redundancy](#redundancy)
  - [Weekly managerial email](#weekly-managerial-email)
- [Unusual Behaviour](#unusual-behaviour)
- [Potential Iterations](#potential-iterations)
- [Further Mitigation](#further-mitigation)
- [Citations](#citations)

# Executive Summary

Log forwarding has been set up for both the Web servers in the environment. These have been set up to forward to the Kali system where active monitoring happens. Certain limits have been instituted to raise flags and alert the IT team of tese events. Additionally, a weekly ermail will be sent to management with the weeks statistics.


# Workflow:

## Purpose:

The purpose of this presentation is to explain the processes and steps taken in monitoring the log files from the two live web servers in order to identify any problems and/or any indicators of attack.


### What is monitored:

There are 2 production web servers on the network that are publicly available and for the purpose of assisting the youth in a range of rural communities to seek employment.

- Internet Information Services (IIS) version 10.0.20348.1, running on a Windows Server 2022
- Apache/2.4.41, Running on Ubuntu 20.04.6 LTS

The log files for both of these web servers are being monitored for any unusual activity. This includes:
- Any Failed logins on days that are not Tuhrsday
- High number of failed logins on Thursdays
- Failed page requests (404s)


### When does monitoring occur:

While there are specific times that are of interest to the core function of Turn a New Leaf, the servers are monitored on a continual basis, 24 hours a day, 7 days a week.

The times of particular interest are:
- Friday midnight (00:00AM) to Wednesday Midnight (11:59PM)
  - All login-attempts are of concern
- Thursday (00:00AM – 11:59PM) – failed login attempts
- Thursday – failed logs with constant time between them (build logic) (2)
- Thursday – excessive failed logins in short time (2)


## Programming:

In the course of setting up the monitoring of the web server logs for Turn a New Leaf, three different operating systems were used. The main Operating system for monitoring all of the log files is Kali Linux. The 2 web servers are running Windows Server 2022 on one and Ubuntu 20.04.6 LTS on the other



### Windows
Programming on the Windows web server was required to send the logs through to the Kali-Linux Log server. This was accomplished using Windows PowerShell and that script is being implemented on an on-going basis by Windows Task Scheduler.


### Ubuntu
Programming on the Ubuntu web server was conducted using SublimeText3 IDE.


### Kali-Linux

Similar to the Ubuntu web server, the programming was completed on SublimeText3 IDE and run using the BASH[^3] scripting language. The script is run by default each time the server powers on by using Crontab[^1].

## Expected output

All of the server web logs are sent to the Kali Linux log server for processing. The logs from the Windows server and the Ubuntu server are processed separately, each by its own script. This is necessary because the two servers produce different types of logs, each with its own syntax.

The output for both of the scripts is identical however, saving the human-readable information in the following structure:



### For page-not-found errors:

/home/user/logMonitor/404/\<ip address\>/\<date\>.log [^2]

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

/home/logMonitor/401/\<ip address\>/\<date\>.log [^2]

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

### Setting up the log forwarding on Windows Server 2022 for ISS

A script was created in PowerShell. This is linked [here](send_iis_logs.ps1). Once the script was saved, we needed to ensure that it was constantly run in the background each time the server started[^4]. To do this we create a new Task in Windows Task Scheduler with the following properties:
- Description: `Send IIS logs to log server`
- Start: `When the computer starts`
- Action: `Start a program`
- Program/Script: `C:\Users\Administrator\send_iis_logs.ps1`
- Arguments: `-ExecutionPolicy Bypass -File “C:\Users\Administrator\send_iis_logs.ps1”`
- Run: `At startup, whether user is logged on or not and with highest privileges`

### Setting up the log forwarding on Ubuntu 20.04.6 LTS for Apache2

Setting up log forwarding on Linux is a lot easier than on Windows and required very little setup. All that's needed is to install `rsyslog` and edit the config file in `/etc/rsyslog.conf` by simply adding:

```
module(load="imfile" PollingInterval="10" statefile.directory="/var/spool/rsyslog")
input(type="imfile" File="/var/log/apache2/*.log" Tag="apache_logs" Severity="info" Facility="local1")
local1.* @172.16.14.51.514
```

### Setting up the Log Server on Kali-Linux

Similarly, setting up the Kali server to receive the logs was relatively easy. Installing `rsyslog` was required followed by 

```
$template IISLogFormat, "/var/log/iis/%HOSTNAME%.log"
*.* ?IISLogFormat
```

Once set up the Log server started receiving logs from both web servers ready for processing.

### Log File Processing

To process the logs, two script are run at boot time[^1] and never stop. Those scripts are located [here (Apache)](apache.sh) and [here (IIS)](iis.sh). These scripts are identical, except for the fact that they monitor the logs from their respective web servers. At their core, they watch the incoming logs in real-time and search for key-words using Regular Expressions[^6]. When those key-words are located, some processing takes place and outputs human-readable log files making further investigation much easier should it be required. There is also further logic to take action by sending emails to the log analyst should certain limits be reached. These scripts are also run in their own screen instances so that they cannot accidentally be shut down.

### Redundancy

As it is critical to have the scripts running on Thursdays, there is an additional check that is run on Wednesday, 10 minutes before midnight[^1]. This script is located [here](double-check.sh). It searches the currently running processes on the Log Server and ensures that the monitoring scripts (apache.sh and iis.sh) are both running. If the log  processing scripts are not running, the script-monitoring script, initiates them again.

### Weekly managerial email

As a part of the process of monritoring, a weekly email is generated based on the logs generated over the last week and that email is then sent to the manager. The script that manages that is located [here](weekly.sh). This script puts together all the statistics from the last week and sends it off to the manager on Friday morning.

An example of the email that would be sent to a manager would look like this:

```
From: LogServer <kali@turnanewleaf.ca>
To: Management <manager@turnanewleaf.ca>
Cc: Jim Sher <jim@turnanewleaf.ca>
Subject: Weekly Log Summary

Top 3 IP addresses for 404s over the last 7 days:
192.168.1.100  : 35 attempts
192.168.1.50   : 29 attempts
192.168.1.200  : 24 attempts

Top 3 IP addresses for 401s over the last 7 days:
192.168.1.150  : 17 attempts
192.168.1.80   : 12 attempts
192.168.1.30   : 8 attempts
```

## Unusual Behaviour

Before starting to code up how to process the incoming log files, we need to determine how we'll need to decide what sort of activity requires monitoring, followed by what activity would require immediate attention.

We decided that  the following could be considered to be Indicators or Attack:

- Multiple Failed login attempts on Thursdays
  
  As the service provided by **Turn a New Leaf** requires its clients to log in each Thursday, there would naturally be failed login attempts for various reasons, however, a large number could indicate an attack.
- Any login attempts on Friday through Wednesday
  
  As the Service is only intended for use on Thursdays, any failed login attempts on other days of the week could indicate an attempted attack.
- Attempted access to non-existent pages
  
  One way that a threat actor could possibly try attain Initial Access[^5] would be to locate a web page through reconnaissance on one of the servers that is no intended for public access and then try gain access via logging in on that page.

## Potential Iterations

As this is an initial monitoring solution, regular meetings should be held to determine whether the implemented monitoring is stringent enough or if too many false-positives are being generated. Further fine tuning could make the monitoring more effective. 

More thought should be invested in this monitoring solution with specific regards to further monitoring in other aspects of the web site. these could include:

- Bandwidth monitoring:
  
  Any spikes in the bandwidth usage could indicate a DDoS attack or prolonged increase in data throughput could indicate attempted data exfiltration.
- GEO-IP monitoring:
  
  As the only logins are expected to come from local rural communities, there is no need to allow any access to the web site from anywhere that is not in Canada.
  Further, we could even create a white-list of allowed IP addresses if it is plausible, as opposed to black-listing non-Canadian IP ranges.

## Further Mitigation

As the web site is only used by the public on Thursdays, there is no reason to allow anyone to view the web pages on the other days of the week. Some ways to make the site more secure would be to:
- Shut off the servers on Friday morning shortly after midnight, and then bring them online again Just before midnight on Wednesday night.
- A less-severe approach would be to lock down the HTTP ports (80 & 443) during the inactive hours.
- If the above is still too severe, simply disabling the log-in fields during those times would still make the site slightly more secure.

## Citations


[^1]: [crontab Guru](https://crontab.guru/) can be used to get the correct formatting for Cronjobs (scheduling tasks) run in a linux environment. 
[^2]: [HTTP Status codes](https://www.semrush.com/blog/http-status-codes/) are used by web servers to differentiate different types of reponses. In this case, we've used 401 - 'Unauthorised' and 404 - 'Page not Found'. The 500 errors (Server Errors) do not indicate failed logins or attempted attakes, so those were left out.
[^3]: All of the BASH script was coded by hand without any commenting. This is bad practise as it would be very hadrd for anyone else to decypher the code at a later point. So [Chat GPT](https://chat.openai.com/) was used to comment the code automatically.
[^4]: The contents of this page on [Lazy Admin](https://lazyadmin.nl/powershell/how-to-create-a-powershell-scheduled-task/) runs through the process of setting up the Windows Task Scheduler to automatically run a script at system boot.
[^5]: The [MITRE ATT&CK Framework](https://attack.mitre.org/) Lists a number of ways a threat actor can gain [Initial Access](https://attack.mitre.org/tactics/TA0001), however, in this instance we are specifically interested in [Exploit Public-Facing Application](https://attack.mitre.org/techniques/T1190/).
[^6]: The Regex in both the Apache and ISS scripts were tested and confirmed using [Regex101](https://regex101.com/)
