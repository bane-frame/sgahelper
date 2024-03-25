#!/bin/bash

############################################################
#                       SGA Helper v1.7.6                  #
############################################################

### begin of service management functions ###
# function to enable service
function enable_service() {
    echo "Enabling the service..."
    systemctl enable "$1"
    systemctl start "$1"
    systemctl status "$1"
}

# function to disable service
function disable_service() {
    echo "Disabling the service..."
    systemctl stop "$1"
    systemctl disable "$1"
    systemctl status "$1"
}

# function to check service status
function service_status() {
    state=$(systemctl is-active "$1")
        if echo "$state" | grep active > /dev/null 2>&1;
            then echo "RUNNING"
            else echo "DOWN"
        fi
}
### end of service management functions ###

### begin password management ###

# function to enable SSH password authentication
function enable_password_auth() {
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    echo "Password authentication enabled for SSH."
}

# function to disable SSH password authentication
function disable_password_auth() {
    sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd
    echo "Password authentication disabled for SSH."
}

# function to check if password authentication is enabled
function is_password_auth_enabled() {
    sudo grep -qE '^ *PasswordAuthentication\s+yes' /etc/ssh/sshd_config
    return $?
}

# function to check if password authentication is disabled
function is_password_auth_disabled() {
    sudo grep -qE '^ *PasswordAuthentication\s+no' /etc/ssh/sshd_config
    return $?
}
### end password management ###

### protocol statistics functions ###
# function for FRP7
function FRP7() {
count7=`sudo netstat -an | grep :443 | grep EST | uniq | wc -l`
count71=$(($count7/2))
echo $count71
}

# function for FRP8
function FRP8() {
count8=`sudo netstat -anp | grep turn | grep -v 127 | grep udp | uniq | wc -l`
count81=$(($count8-2))
echo $count81
}
### end of protocol statistics ###

### main menu function ###
function main_menu() {
sp=$(service_status app_mgmt_web.service)
sf7=$(service_status nginx.service)
sf8=$(service_status coturn.service)
clear
echo "SGA Helper v1.7.6"
echo "----------------------------------"
echo " "
# health dashboard
echo "SGA services health:"
echo " "
echo "SGA status page is         [$sp]"
echo "NGINX/FRP7 protocol is     [$sf7]"
echo "Coturn/FRP8 protocol is    [$sf8]"
if [ $# -ne 1 ]; then
    echo "Usage: $0 [enable|disable]"
    exit 1
fi
echo " "
echo "----------------------------------"
echo " "
# choice
echo "1. Enable status page service"
echo "2. Disable status page service"
echo "3. Connection statistics on SGA"
echo "4. Test STUN communication"
echo "5. Test NGINX configuration"
echo "6. Show NGINX errors"
echo "7. Cleanup log partition"
echo "8. Disable nonce mechanism - WARNING this will drop all FRP8 connections"
echo "9. Toggle SSH password authentication"
echo "0. Exit"
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
        clear
        # see the current number of connections to SGA
        echo "FRP8 (UDP only) connections:" ; FRP8
        echo "FRP7 connections:" ; FRP7
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    4)  
        clear
        echo "Expected result is the public IP address of SGA"
        echo "which should be same as public IP associated with FQDN"
        echo " "
        # test communication with stun.console.nutanix.com
        /usr/local/bin/external_ip_via_stun.sh stun.console.nutanix.com
        echo " "
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    5)  
        clear
        echo "Testing NGINX configuration..."
        # size check
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
        clear
        # show nginx errors
        tail /var/log/nginx/error.log
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    7)  
        clear
        echo "Showing current usage per file:"
        sudo du -sh /var/log/* | sort -k 1 -n -r
        echo "=================== FORCING LOG ROTATION ==================="
        # force log rotation to cleanup /var/log partition
        sudo find /etc/logrotate.d/ -type f -name '*' -print0 | sudo xargs -0 logrotate -f -d
        read -p "Press enter to go back on main menu"
        main_menu
        ;;
    8)  
        clear
        # make backup of coturn unit
        sudo cp /etc/systemd/system/coturn.service /home/nutanix/coturn.service.bak
        # remove nonce mechanism from coturn configuration
        sudo sed -i '/nonce/d' /etc/systemd/system/coturn.service
        # restart coturn service with new configuration
        sudo systemctl daemon-reload
        sudo systemctl restart coturn
        # check service status if fails revert backup
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
        clear
        # Perform the action based on the argument
        case "$1" in
            "enable")
                if is_password_auth_enabled; then
                    echo "Password authentication is already enabled for SSH."
                else
                enable_password_auth
                fi
                ;;
            "disable")
                if is_password_auth_disabled; then
                    echo "Password authentication is already disabled for SSH."
                else
                    disable_password_auth
                fi
                ;;
            *)
                echo "Invalid option. Usage: $0 [enable|disable]"
                exit 1
                ;;
        esac
    0)  
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
### end of main menu fuction ###
}
# begin
main_menu
# end