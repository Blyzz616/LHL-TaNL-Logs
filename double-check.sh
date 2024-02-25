#!/bin/bash

# Check if Apache script is not running
if ! pgrep -f "apache.sh" > /dev/null ; then
    /usr/bin/screen -S "Apache" -d -m bash -c "/home/kali/apache.sh"
fi

# Check if IIS script is not running
if ! pgrep -f "iis.sh" > /dev/null ; then
    /usr/bin/screen -S "IIS" -d -m bash -c "/home/kali/iis.sh"
fi
