#!/bin/bash

############################################################
# Script for SGA 3.x Web console service management v1.6.5 #
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

# function to check service status
service_status() {
    state=$(systemctl is-active "$1")
        if echo "$state" | grep active;
            then echo "RUNNING"
            else echo "DOWN"
        fi
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
sp=$(service_status app_mgmt_web.service)
sf7=$(service_status nginx.service)
sf8=$(service_status coturn.service)
clear
echo "SGA Helper v1.6.5"
echo "----------------------------------"
echo " "
echo "SGA service health:"
echo " "
echo "SGA status page is         [$sp]"
echo "NGINX/FRP7 protocol is     [$sf7]"
echo "Coturn/FRP8 protocol is    [$sf8]"
echo " "
echo "----------------------------------"
echo " "
echo "1. Enable status page service"
echo "2. Disable status page service"
echo "3. Connection statistics on SGA"
echo "4. Test STUN communication"
echo "5. Test NGINX configuration"
echo "6. Show NGINX errors"
echo "7. Cleanup log partition"
echo "8. Disable nonce mechanism - WARNING this will drop all FRP8 connections"
echo "9. Exit"
echo " "

read -p "Enter your choice: " choice

case $choice in
    1)
        clear
        enable_service app_mgmt_web.service
        enable_service app_mgmt_web_secure.service
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    2)
        clear
        disable_service app_mgmt_web.service
        disable_service app_mgmt_web_secure.service
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    3)
        # see the current number of connections to SGA
        clear
        echo -e "FRP8 connections:" ; FRP8
        echo -e "FRP7 connections:" ; FRP7
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    4)  
        # test communication with stun.console.nutanix.com
        clear
        echo -e 'Expected result is the public IP address of SGA'
        echo -e 'which should be same as public IP associated with FQDN'
        /usr/local/bin/external_ip_via_stun.sh stun.console.nutanix.com
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    5)  
        # test nginx configuration
        clear
        echo -e 'Testing NGINX configuration...'
        filesize=$(stat -c%s "/etc/nginx/nginx.conf")
        echo "Size of configuration file is $filesize bytes."
            if (( filesize > 0 )); then
                echo "NGINX configuration file size is greater than 0, checking syntax..."
                sudo /usr/sbin/nginx -t
            else
                clear
                echo "NGINX configuration is NOT VALID, please consult Frame documentation and check if CIDR range is valid"
                echo " "
                echo "Due to memory use and performance considerations, maximum size of network should be limited to /18."
                echo "Also consider that CIDR notation should be ending with zero eg. 10.0.0.0/18"
            fi
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    6)  
        # show nginx errors
        clear
        tail /var/log/nginx/error.log
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    7)  
        # force log rotation to cleanup /var/log partition
        clear
        sudo du -sh /var/log/* |sort -k 1 -n -r
        echo -e "==================== FORCING LOG ROTATION ==============================="
        sudo find /etc/logrotate.d/ -type f -name '*' -print0 | sudo xargs -0 logrotate -f -d
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    8)  
        # make backup of coturn unit
        clear
        sudo cp /etc/systemd/system/coturn.service /home/nutanix/coturn.service.bak
        # remove nonce mechanism from coturn configuration
        sudo sed -i '/nonce/d' /etc/systemd/system/coturn.service
        # restart coturn service with new configuration
        sudo systemctl daemon-reload
        sudo systemctl restart coturn
        # check service status
        STATUS="$(systemctl is-active coturn.service)"
            if [ "${STATUS}" = "inactive" ]; then
                echo "Service not running as expected, reverting backup"
                sudo cp /home/nutanix/coturn.service.bak /etc/systemd/system/coturn.service
                sudo systemctl daemon-reload
                systemctl restart coturn
            else 
                exit 1  
            fi
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    9)  
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
main_menu
# end