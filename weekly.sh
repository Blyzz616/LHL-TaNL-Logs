#!/bin/bash

# Define the directory paths
LOG_MONITOR_DIR="/home/kali/logMonitor"
FOF_DIR="$LOG_MONITOR_DIR/404"
FOO_DIR="$LOG_MONITOR_DIR/401"

# Initialize variables to store results
FOF_RESULTS=""
FOO_RESULTS=""

# Function to process 404 log files
process_404_logs() {
    dir="$1"
    date_today=$(date +%Y-%m-%d)
    date_seven_days_ago=$(date -d "7 days ago" +%Y-%m-%d)

    # Iterate through IP directories
    for ip_dir in "$dir"/*; do
        if [[ -d "$ip_dir" ]]; then
            # Iterate through log files in IP directories
            for log_file in "$ip_dir"/*.log; do
                if [[ -f "$log_file" ]]; then
                    # Extract date from log file name
                    log_date=$(basename "$log_file" .log)
                    if [[ "$log_date" -ge "$date_seven_days_ago" && "$log_date" -le "$date_today" ]]; then
                        # Read number of attempts from the first line# Accumulate IP and attempts information
                        FOF_RESULTS+=$(printf "%-15s: %d attempts\n" "$(basename "$ip_dir")" "$num_attempts")
                    fi
                fi
            done
        fi
    done
}

# Function to process 401 log files
process_401_logs() {
    dir="$1"
    date_today=$(date +%Y-%m-%d)
    date_seven_days_ago=$(date -d "7 days ago" +%Y-%m-%d)

    # Iterate through IP directories
    for ip_dir in "$dir"/*; do
        if [[ -d "$ip_dir" ]]; then
            # Iterate through log files in IP directories
            for log_file in "$ip_dir"/*.log; do
                if [[ -f "$log_file" ]]; then
                    # Extract date from log file name
                    log_date=$(basename "$log_file" .log)
                    if [[ "$log_date" -ge "$date_seven_days_ago" && "$log_date" -le "$date_today" ]]; then
                        # Read number of attempts from the first line
                        num_attempts=$(head -n 1 "$log_file")

                        # Accumulate IP and attempts information

                        num_attempts=$(head -n 1 "$log_file")
                        # Read number of attempts from the first line
                        num_attempts=$(head -n 1 "$log_file")

                        # Accumulate IP and attempts information
                        FOO_RESULTS+=$(printf "%-15s: %d attempts\n" "$(basename "$ip_dir")" "$num_attempts")
                    fi
                fi
            done
        fi
    done
}

# Process 404 logs
process_404_logs "$FOF_DIR"

# Process 401 logs
process_401_logs "$FOO_DIR"

# Sort and extract top 3 IPs with most attempts for both 404s and 401s
top_3_404=$(echo "$FOF_RESULTS" | sort -k2 -nr | head -n 3)
top_3_401=$(echo "$FOO_RESULTS" | sort -k2 -nr | head -n 3)

# Prepare email body
email_body="Top 3 IP addresses for 404s over the last 7 days:\n$top_3_404\n\nTop 3 IP addresses for 401s over the last 7 days:\n$top_3_401"

# Send email
echo -e "$email_body" | mail -s "Weekly Log Summary" "manager@turnanewleaf.ca"
