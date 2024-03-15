#!/bin/bash

#
# Script for SGA 3.x Web console service management v1.0
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
echo "3. Exit"

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
        # goto end
        echo "Exiting the script"
        exit 0
        ;;
    *)
        echo "Invalid choice. Please choose 1, 2, or 3."
        ;;
esac
# end of script
