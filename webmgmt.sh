#!/bin/bash

############################################################
# Script for SGA 3.x Web console service management v1.4.9 #
############################################################

# begin of service management functions
# function to enable service
enable_service() {
    echo "Enabling the service..."
    systemctl enable "$1"
    systemctl start "$1"
    systemctl status "$1"
}

# function to disable service
disable_service() {
    echo "Disabling the service..."
    systemctl stop "$1"
    systemctl disable "$1"
    systemctl status "$1"
}
# end of service management functions

# protocol statistics funtctions
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
# end of protocol statistics

# main menu function
main_menu() {
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
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    2)
        disable_service app_mgmt_web.service
        disable_service app_mgmt_web_secure.service
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    3)
        # see the current number of connections to SGA
        echo -e "FRP8 connections:" ; FRP8
        echo -e "FRP7 connections:" ; FRP7
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    4)  
        # test communication with stun.console.nutanix.com
        echo -e 'Expected result is the public IP address of SGA which should be same as public IP associated with FQDN'
        /usr/local/bin/external_ip_via_stun.sh stun.console.nutanix.com
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    5)  
        # test nginx configuration
        echo -e 'Testing NGINX configuration...'
        filesize=$(stat -c%s "/etc/nginx/nginx.conf")
        echo "Size of $filesize bytes."
            if (( filesize > 0 )); then
                echo "NGINX configuration is greater than 0, checking syntax..."
                sudo /usr/sbin/nginx -t
            else
                echo "NGINX configuration is NOT VALID, please consult Frame documentation and check if CIDR range is valid"
            fi
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    6)  
        # force log rotation to cleanup /var/log partition
        sudo du -sh /var/log/* |sort -k 1 -n -r
        echo -e "==================== FORCING LOG ROTATION ==============================="
        sudo find /etc/logrotate.d/ -type f -name '*' -print0 | sudo xargs -0 logrotate -f -d
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    7)  
        # goto end
        echo "Exiting the script"
        exit 0
        ;;
    *)
        echo "Invalid choice. Please choose one of the numbers in the main menu"
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
esac
# end of main menu fuction
}
# begin
clear
main_menu
# end