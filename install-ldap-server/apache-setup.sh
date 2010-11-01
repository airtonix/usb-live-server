#!/bin/sh
SCRIPT_PATH="$(readlink -f $(dirname "$0"))"
. $SCRIPT_PATH/lib/coloured_messages.sh
. $SCRIPT_PATH/lib/file-tools.sh

APACHE_PRESEED_PATH=${SCRIPT_PATH}/apache-preseed

echo "ServerName localhost" | sudo tee /etc/apache2/conf.d/fqdn

# Create Main Website Virtualhost and Relevant Avahi Alias

for file in `ls ${APACHE_PRESEED_PATH}/`;do
	while read LINE; do
		case "`first_character $LINE`" in
			"#" )
				message "hash directive found"

				;;
			* )
				message "user groups"

				;;
		esac
	done < ${APACHE_PRESEED_PATH}/$file
done

message "Setup of Apache-Webserver Done" "success"

