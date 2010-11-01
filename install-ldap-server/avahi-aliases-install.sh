#!/bin/sh
SCRIPT_PATH=${0%/*}
. $SCRIPT_PATH/lib/coloured_messages.sh

message "Install Avahi Aliases Manager" "header"
for file in `ls ./avahi-aliases/*`;do
	message "${file}"
	sudo chmod 777 ${file}
	sudo chmod +x ${file}
	sudo chown root:root ${file}
	sudo cp ${file} /usr/bin/
done

message "Making avahi-aliases list directory" "header"
message "Use this directory to place individual lists of avahi-aliases."
sudo mkdir /etc/avahi/aliases.d/

message "Making central avahi-aliases file" "header"
sudo touch /etc/avahi/aliases

message "Installation of Avahi-Aliases Done" "success"

