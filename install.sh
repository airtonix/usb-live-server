#!/bin/sh
SCRIPT_PATH=${0%/*}
source $SCRIPT_PATH/ldap-server/lib/coloured_messages.sh

message "Preventing Kernel From Being Upgraded" "header"
sudo aptitude hold initramfs-tools grub-pc grub-common grub linux-image
message "remember not to install any packages that require a new grub or linux-image" "warning"

message "Latest Chrome PPA" "header"
message "web-browser"
sudo add-apt-repository ppa:chromium-daily/ppa
message "Latest Talika PPA"
message "task-bar"
sudo add-apt-repository ppa:webupd8team/talika
message "Latest Cardapio PPA"
message "menu"
sudo add-apt-repository ppa:cardapio-team/unstable

message "Update Software List"
sudo apt-get update

message "Install Software"
sudo apt-get install libapache2-mod-python python-mysqldb python-django-* python-yaml python-cjson python-psycopg2 python-sqlite unrar cardapio talika chromium-browser nautilus-filename-repairer nautilus-open-terminal nautilus-actions nautilus-share nautilus-wallpaper nautilus-sendto*

