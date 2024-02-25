$logDirectory = "C:\inetpub\logs\LogFiles"
$logPattern = "*.log"

# Infinite loop to continuously tail log files
while ($true) {
    # Get list of log files matching the pattern
    $logFiles = Get-ChildItem -Path $logDirectory -Filter $logPattern

    # Iterate through each log file
    foreach ($logFile in $logFiles) {
        # Open the log file and read new lines
        $fileStream = [System.IO.File]::Open($logFile.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        $streamReader = New-Object System.IO.StreamReader($fileStream)
        $streamReader.BaseStream.Seek(0, [System.IO.SeekOrigin]::End)

        while ($true) {
            $line = $streamReader.ReadLine()
            if ($line -ne $null) {
                # Send the log line to rsyslog (replace <rsyslog_ip> and <port> with your rsyslog server's IP and port)
                Write-Host "Sending log line: $line"
                $udpClient = New-Object System.Net.Sockets.UdpClient
                $bytes = [System.Text.Encoding]::ASCII.GetBytes($line)
                $udpClient.Send($bytes, $bytes.Length, "<rsyslog_ip>", <port>)
            }
            else {
                # Wait for new lines to be written to the log file
                Start-Sleep -Milliseconds 100
            }
        }

        # Close the file stream
        $streamReader.Close()
        $fileStream.Close()
    }

    # Wait before checking for new log files
    Start-Sleep -Seconds 10
}
