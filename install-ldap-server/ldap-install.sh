#!/bin/sh
SCRIPT_PATH=${0%/*}
. $SCRIPT_PATH/lib/coloured_messages.sh

message "Backuping Up Static Hosts File" "header"
sudo cp /etc/hosts /etc/hosts.pre-ldap-config

message "Restarting avahi-daemon" "header"
sudo service avahi-daemon stop
sudo service avahi-daemon start

message "Install Terminal Tools" "header"
# 1. Install utilities
sudo apt-get install openssh-server synergy terminator

message "Installing LDAP SERVER" "header"
# 1. Install ldap and migration tools
sudo apt-get install slapd ldap-utils migrationtools

message "Force Reconfigure" "header"
sudo dpkg-reconfigure slapd

message "Installation of LDAP-Server Done" "success"
message "Remember to run ldap-setup" "warning"

