#!/bin/bash

LOGPATH="/home/kali/LogMonitor"  # Directory where log files are stored

# Global variables initialization
IP=""
timeStamp=""
dateStamp=""
userAgent=""
start=""

# Function to handle 404 errors
funcFOF(){
  # Extracting failed page URL
  failedPage=$(echo "$LINE" | grep -oE 'GET\s.*404' | cut -c5- | rev | cut -c15- | rev)
 
  # Extracting IP address
  IP=$(echo "$LINE" | grep -oE '\s(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])' | cut -c2-)
 
  # Extracting timestamp
  timeStamp=$(echo "$LINE" | grep -oE 'T[0-9]{2}:[0-9]{2}:[0-9]{2}' | cut -c2-)
 
  # Extracting datestamp
  dateStamp=$(date -d $(echo "$LINE" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}') +"%b %d, %Y - %a")
 
  # Extracting user-agent
  userAgent=$(echo "$LINE" | grep -oE '[0-9]{3}\s[0-9]+\s"\S+"\s"(.*)' | sed -E 's/.*"(.*)"$/\1/')

  # If the log file for the current date and IP does not exist, create it
  if [[ ! -f "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log" ]]; then
    mkdir -p "$LOGPATH/404/$IP"
    touch "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log"
    echo "1" >> "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log"
  else
    # Increment the count of failed pages in the log file
    count=$(grep -cE '^Failed\sPage' "logMonitor/404/$IP/$(date +%Y-%m-%d).log")
    ((count++))
    sed -i "1s/.*/$count/" "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log"
   
    # If the count reaches 5, send an email notification
    if [[ "$count" -eq 5 ]]; then
      start=$(grep -E '^Time' "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log" | head -n1 | cut -d' ' -f2)
      funcFOFMail
    fi
  fi

  # Append information to the log file
  echo "Failed Page: $failedPage" >> "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log"
  echo "From IP Address: $IP" >> "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log"
  echo "Time: $timeStamp" >> "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log"
  echo "Date: $dateStamp"  >> "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log"
  echo "Useragent: $userAgent" >> "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log"
  echo "" >> "$LOGPATH/404/$IP/$(date +%Y-%m-%d).log"
}

# Function to handle 401 errors
funcFOO(){
  # Extracting IP address
  IP=$(echo "$LINE" | grep -oE '\s(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])' | cut -c2-)
 
  # Extracting timestamp
  timeStamp=$(echo "$LINE" | grep -oE 'T[0-9]{2}:[0-9]{2}:[0-9]{2}' | cut -c2-)
 
  # Extracting datestamp
  dateStamp=$(date -d $(echo "$LINE" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}') +"%b %d, %Y - %a")
 
  # Extracting user-agent
  userAgent=$(echo "$LINE" | grep -oE '[0-9]{3}\s[0-9]+\s"\S+"\s"(.*)' | sed -E 's/.*"(.*)"$/\1/')

  # If the log file for the current date and IP does not exist, create it
  if [[ ! -f "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log" ]]; then
    mkdir -p "$LOGPATH/401/$IP"
    touch "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log"
    echo "1" >> "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log"
  else
    # Increment the count of failed pages in the log file
    count=$(grep -cE '^Failed\sPage' "logMonitor/401/$IP/$(date +%Y-%m-%d).log")
    ((count++))
    sed -i "1s/.*/$count/" "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log"

    # If the count reaches 5, send an email notification
    if [[ "$count" -eq 5 ]]; then
      start=$(grep -E '^Time' "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log" | head -n1 | cut -d' ' -f2 )
      funcFOOMail
    fi
  fi

  # Append information to the log file
  echo "Failed Page: $failedPage" >> "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log"
  echo "From IP Address: $IP" >> "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log"
  echo "Time: $timeStamp" >> "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log"
  echo "Date: $dateStamp"  >> "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log"
  echo "Useragent: $userAgent" >> "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log"
  echo "" >> "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log"
}

# Function to send email notification for excessive 404 errors
funcFOFMail(){
  subject="Excessive 404 errors"
  recipient="jim@turnanewleaf.ca"
  body="There have been a lot of 404s from $IP starting at $start. Please investigate"

  # Send email notification
  mail -s "$subject" "$recipient" <<EOF
$body
EOF
}

# Function to send email notification for excessive 401 errors
funcFOOMail(){
  subject="Excessive 401 errors"
  recipient="jim@turnanewleaf.ca"
  body="There have been a lot of failed logins from $IP starting at $start. Please investigate, the time delta between 401s is:"

  # Extracting timestamps from the log file
  readarray -t times < <(grep 'time: .*' "$LOGPATH/401/$IP/$(date +%Y-%m-%d).log" | cut -d' ' -f2)

  prev_time=""
  index=0

  # Calculating time delta between 401 errors
  for current_time in "${times[@]}"; do
    current_seconds=$(date -d "$current_time" +%s)
    if [ -n "$prev_time" ]; then
      difference=$((current_seconds - prev_seconds))
      body+="\n%d seconds" "$difference"
    fi
    prev_seconds="$current_seconds"
    prev_time="$current_time"
    ((index++))
  done

  # Send email notification
  mail -s "$subject" "$recipient" <<EOF
$body
EOF
}

# Main loop to read log lines and process errors
tail -fn0 /var/log/iis/user-pc.log | \
  while read -r LINE; do
    # Checking for 404 errors
    fourOHfour=$(echo "$LINE" | grep -cE 'HTTP\/[0-9]\.[0-9]\" 404')
    if [[ "$fourOHfour" -gt 0 ]]; then
      funcFOF
    fi
   
    # Checking for 401 errors
    fourOHone=$(echo "$LINE" | grep -cE 'HTTP\/[0-9]\.[0-9]\" 404')
    if [[ "$fourOHone" -gt 1 ]]; then
      funcFOO
    fi
  done
