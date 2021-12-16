#!/bin/bash

# pull scanner from local
# https://github.com/logpresso/CVE-2021-44228-Scanner
#
# This wrapper will use logpresso and loop through common directories to scan with an option to pass in the java path.



COMMON_DIRS=("/var" "/opt" "/usr" "/home" "/tmp")
java_option="$1"

# Local clone from logpresso git repository
local_filebrowser="http://localfilebrowser.com"

# find java, if cant, check for passed in parameter
if [[ -z "$java_option" ]]; then
  java_path=$(find /usr -type f -name "java" | grep -v 'bash-completion' |  head -n 1)
else
  java_path="$1"
fi


if [[ -z "$java_path" ]]; then
  echo "Cannot find java. Pass in location or install openjdk."
  exit 1
fi

if [[ ! -x "$java_path" ]]; then
  echo "Java found in $java_path is not executable. Please pass in a location or install openjdk on the server."
  exit 2
fi

wget_path=$(whereis wget | awk '{print $2}')

if [[ -z "$wget_path" ]]; then
  echo "wget not found. what?"
  exit 3
fi

$wget_path -q $local_filebrowser/logpresso/logpresso-log4j2-scan-1.5.0.jar -P /tmp

os_check=$(uname -a | awk '{print $1}')

# Skip over nfs or auto mounts
avoid_mounts=$(cat /proc/mounts | grep nfs | awk '{print $2}' > /tmp/log4j_avoid.txt)

# Check for empty newline at the end of file.
if [[ $(tail -c1 /tmp/log4j_avoid.txt | wc -l) == 1 ]]; then
  awk 'NF' /tmp/log4j_avoid.txt > /tmp/file.tmp
  mv /tmp/file.tmp /tmp/log4j_avoid.txt
fi

# Start scanning and looping through common directories
echo "Starting log4j scan..."
for i in "${COMMON_DIRS[@]}"
do
    echo "Checking $i:"
    $java_path -jar /tmp/logpresso-log4j2-scan-1.5.0.jar --exclude-config /tmp/log4j_avoid.txt $i
    echo " "
done

# Cleanup mess when done.
rm -rf /tmp/logpresso-log4j2-scan-1.5.0.jar
rm -rf /tmp/log4j_avoid.txt