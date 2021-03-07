#!/bin/bash

# user name
username="kiran"

# S3 bucket id
s3_bucket="upgrad-kiran"

#Check for root user permission 
if [ `whoami` != "root" ]
then 
	echo "root privilages required to execute the script."
	echo "run script with sudo privilages."
	exit
fi

# Update package list 
apt update -y 

#check for Apache installation
package=$(dpkg --list | grep "apache2")

if [ "$package" == "" ]
then
	echo "Apache web server not installed..."
	echo "Installing now..."
	sleep 2
	apt install apache2 -y
	echo "Apache web server installed."
	sleep 5
fi

#Apache service status check 
echo "Checking Apache server status..."
status=$(service apache2 status | grep "running")

if [ "$status" == "" ]
then
	echo "Starting Apache server ..."
	service apache2 start
	sleep 5
else
	echo "Apache Web Server Running ..."
fi

#Create archive of apache log
cd /var/log/apache2/

date_time=$(date '+%d%m%Y-%H%M%S')
filename=$username"-httpd-logs-"$date_time

tar -cf ${filename}.tar *.log

#copy archive to s3 bucket
aws s3 cp ${filename}.tar s3://${s3_bucket}/${filename}.tar

# Iventory hosting check
inv_file="/var/www/html/inventory.html"

if ! [ -f $inv_file ]
then
        touch $inv_file
        echo "<h><b>Log Type &ensp;&ensp;  Date Created  &ensp;&ensp; Type &ensp;&ensp; Size" > $inv_file
fi

# Write data to inventory.html
size=$(ls -lh | grep "$filename" | awk '{print $5}')
echo "<p>httpd-logs &ensp;&ensp; $date_time &ensp;&ensp; tar &ensp;&ensp; $size</p>" >> $inv_file

# Check cron schedule for auto script execution
cron_file="/etc/cron.d/automation"
if ! [ -f $cron_file ]
then
        touch $cron_file
        echo "0 0 * * * root /root/Automation_Project/automation.sh" >> $cron_file
fi

