#!/bin/bash

#
# Script for SGA 3.x Web console service management v1.4.5
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

# function for FRP7
FRP7() {
count7=`sudo netstat -an |grep :443 |grep EST|uniq|wc -l`
count71=$(($count7/2))
echo $count71
}

# function for FRP8
FRP8() {
count8=`sudo netstat -anp |grep turn|grep -v 127|grep udp|uniq|wc -l`
count81=$(($count8-2))
echo $count81
}

# enable or disable service choice
echo "SGA web management script"
echo "----------------------"
echo "1. Enable status page service"
echo "2. Disable status page service"
echo "3. Connection statistics on SGA"
echo "4. Test STUN communication"
echo "5. Test NGINX configuration"
echo "6. Cleanup log partition"
echo "7. Exit"

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
        echo -e "FRP8 connections:" ; FRP8
        echo -e "FRP7 connections:" ; FRP7
        ;;
    4)  
        # test communication with stun.console.nutanix.com
        echo -e 'Expected result is the public IP address of SGA'
        /usr/local/bin/external_ip_via_stun.sh stun.console.nutanix.com
        read -p "Press enter to continue"
        ;;
    5)  
        # test nginx configuration
        echo -e 'Testing NGINX configuration...'
        sudo /usr/sbin/nginx -t
        ;;
    6)  
        # force log rotation to cleanup /var/log partition
        sudo du -sh /var/log/* |sort -k 1 -n -r
        echo -e "==================== FORCING LOG ROTATION ==============================="
        sudo find /etc/logrotate.d/ -type f -name '*' -print0 | sudo xargs -0 logrotate -f -d
        ;;
    7)  
        # goto end
        echo "Exiting the script"
        exit 0
        ;;
    *)
        echo "Invalid choice. Please choose one of the numbers in the main menu"
        ;;
esac
# end of script
