#!/bin/bash

#
# Script for SGA 3.x Web console service management v1.2.1
#

# function to enable the web management service
enable_service() {
    echo "Enabling the service..."
    systemctl enable "$1"
    systemctl start "$1"
    systemctl status "$1"
}

# function to disable the web management service
disable_service() {
    echo "Disabling the service..."
    systemctl stop "$1"
    systemctl disable "$1"
    systemctl status "$1"
}

# enable or disable service choice
echo "SGA web management script"
echo "----------------------"
echo "1. Enable service"
echo "2. Disable service"
echo "3. Connection statistics on SGA"
echo "4. Test STUN communication"
echo "5. Exit"

read -p "Enter your choice: " choice

case $choice in
    1)
        enable_service app_mgmt_web.service
        enable_service app_mgmt_web_secure.service
        ;;
    2)
        disable_service app_mgmt_web.service
        disable_service app_mgmt_web_secure.service
        ;;
    3)
        # see the current number of connections to SGA
        watch -d 'echo -e "FRP8 connections:" ; count8=`sudo netstat -anp |grep turn|grep -v 127|grep udp|uniq|wc -l` ; count81=$(($count8-2)) ; echo $count81 ; echo -e "FRP7 connections:" ; count7=`sudo netstat -an |grep :443 |grep EST|uniq|wc -l` ; count71=$(($count7/2));echo $count71; echo "CTRL+C to exit"'
        ;;
    4)  # test communication with stun.console.nutanix.com
        echo -e 'Expected result is the public IP address of SGA'
        external_ip_via_stun.sh stun.console.nutanix.com
        pause   
    5)  
        # goto end
        echo "Exiting the script"
        exit 0
        ;;
    *)
        echo "Invalid choice. Please choose one of the number in main menu"
        ;;
esac
# end of script
