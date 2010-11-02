#!/bin/sh
SCRIPT_PATH=${0%/*}
. $SCRIPT_PATH/lib/coloured_messages.sh

message "Django" "header"
message "Install [y/n]" "choice"
read pause
case $pause in
	"y" )
		sudo apt-get install libapache2-mod-python python-mysqldb python-django-* libapache2-mod-wsgi libapache2-mod-ldap-userdir libapache2-mod-log-sql-mysql libapache2-mod-auth-kerb libapache2-mod-auth-radius libapache2-mod-vhost-ldap
		sudo apt-get install python-ldap python-setup-tools snakefood python-setupdocs python-setuptools
	;;
	"n" )
	;;
esac


message "Linux Apache Mysql PHP" "header"
message "Install [y/n]" "choice"
read pause
case $pause in
	"y" )
		sudo tasksel install lamp-server

		message "Enable Apache LDAP Module" "header"
		sudo a2enmod authnz_ldap

		message "Restart Apache Webserver" "header"
		sudo service apache2 restart
    
		message "Restart Apache Webserver" "header"
    sudo addgroup webdev-team
    sudo adduser ubuntu webdev-team
	;;
	"n" )
	;;
esac

message "Apache Utils" "header"
message "Install [y/n]" "choice"
read pause
case $pause in
	"y" )

		for file in `ls ./apache-utils/*`;do
			chmod +x ${file}
			sudo chown root:root ${file}
			sudo cp ${file} /usr/bin/
		done
		message "Installation of Apache-Webserver Done" "success"
	;;
	"n" )
	;;
esac

