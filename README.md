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

/home/logMonitor/401/\<ip address\>/\<date\>.log

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

A script was created in PowerShell. This is linked [here](send_iis_logs.ps1). Once the script was saved, We need to ensure that it is contantly run in the background each time the server starts. To do this we Create a new Task in Windows Task Scheduler with the following properties:
- Description: Send IIS logs to log server
- Start: When the computer starts
- Action: Start a program
- Program/Script: C:\Users\Administrator\send_iis_logs.ps1
- Arguments: -ExecutionPolicy Bypass -File “C:\Users\Administrator\send_iis_logs.ps1”
- Run: At startup, whether user is logged on or not and with highest privileges

### Setting up the log forwarding on Ubuntu 20.04.6 LTS for Apache2

Setting up log forwarding on Linux is a lot easier than on Windows and required very little setup. All that's needed is to install `rsyslog` and edit the config file in `/etc/rsyslog.conf` by simply adding:

```
module(load="imfile" PollingInterval="10" statefile.directory="/var/spool/rsyslog")
input(type="imfile" File="/var/log/apache2/*.log" Tag="apache_logs" Severity="info" Facility="local1")
local1.* @172.16.14.51.514
```

### Setting up the Log Server on Kali-Linux

Similarly, setting up the Kali server to recevie the logs was relatively easy. Installing `rsyslog` was required followed by 

```
$template IISLogFormat, "/var/log/iis/%HOSTNAME%.log"
*.* ?IISLogFormat
```

Once set up the Log server started receiving logs from both web servers ready for processing.

### Log File Processing

To process the logs, two script are run at boot time and never stop. Those scripts are located [here (Apache)](apache.sh) and [here (IIS)](iis.sh). These scripts are identical, except for the fact that they monitor the logs from their respective web servers. At their core, they watch the incoming logs in real-time and search for key-words. When those key-words are located, some processing takes place and outputs human-readable log files making further investigation much easier should it be required. There is also further logic to take action by sending emails to the log analyst should certain limits be reached.

### Weekly managerial email

As a part of the process of monirtoring, a weekly email is generated based on the logs generated over the last week and that email is then sent to the manager. The script that manages that is located [here](weekly.sh). This script puts together all the statistics from the last week and sends it off to the manager on Friday morning.


## Unusual Behaviour

Before starting to code up how to process the iuncoming log files, we need to determine how we'll need to decide what sort of activity requires monitoring, followed by what activity would require immediate attention.

We decided that  the following could be considered to be Indicators or Attack:

- Multiple Failed log in attempts on Thursdays
  As the service provided by **Turn a New Leaf** requires it's clients to log in each Thursday, there would naturally be failed login attempts for variouys reasons, however, a large number could indicate an attack.
- Any login attempts on Friday through Wednesday
  As the Service is only intended for use on Thursdays, any failed login attempts on other days of the week could indicate an attmpted attack.
- Attempted access to non-existent pages
  One way that a threat actor could possibly try attain initial Access would be to locate a web page through reconnaissance on one of the servers that is no intended for public access and then try gain access via logging in on that page.

Potential Iterations

As this is an initial monitoring solution, regular meetings should be held to determin whether the implemeted monitoring is stringent enough or if too many false-positives are being generated. Further fine tuning could make the monitoring more effective. 

More thought should be investied in this monitoring solution with specific regards to further monitoring in other aspects of the web site. these could include:

- Bandwidth monitoring:
  Any spikes in the bandwidth usage could indicate a DDoS attack or prolonged increase in data throughput could indicate attempted data exfiltration.
- GEO-IP monitoring:
  As the only logins are expecte to come from local rural communities, there is no need to allow any access the the web site from anywhere that is not in Canada.
  Further, we could even create a whitl-list of allowed IP addresses if it is plausible, as opposed to black-listing non-Canadian IP ranges.

## Further Mitigation

As the web site is only used by the public on Thursdays, there is no reason to allow anyone to view the web pages on the other days of the week. Some ways to make the site more secure would be to:
- Shut off the servers on Friday morning shortly after midnight, and then bring them online again Just before midnight on Wednesday night.
- A less-severe approach would be to lock down the HTTP ports (80 & 443) during the inactive hours.
- If the above is still too severe, simply disabling the log-in fields during those times would still make the site slightly more secure.



