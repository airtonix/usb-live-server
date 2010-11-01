#!/bin/sh
SCRIPT_PATH=${0%/*}
. $SCRIPT_PATH/../lib/coloured_messages.sh
LDAP_ADMIN_DN="Test"
message "LDAP Schema Frontend Data : Users" "header"
message "PRESEED : LDAP USERS" "header"
LDAP_PRESEED_USERS="${SCRIPT_PATH}/users"
message $LDAP_PRESEED_USERS

for file in `ls ${LDAP_PRESEED_USERS}/*`;do
	message "processing : ${file}"
	message "sudo ldapadd -x -D $LDAP_ADMIN_DN -W -f ${file}"
done

