#!/bin/sh

HOSTNAME=$1
AVAHI_DOMAIN=$2
USERS_GID=$3
USERS_UID=$4
TEMP_LDIF_OUTPUT_DIR="/tmp/ldap-setup"

sudo mkdir ${TEMP_LDIF_OUTPUT_DIR}/users/ -p

    echo "username"
    read username
    echo "password"
    read password
    echo "Title"
    read user_title
    echo "Firstname"
    read user_firstname
    echo "Lastname"
    read user_lastname
    echo "initials"
    read user_initials
    echo "Organisation"
    read user_org
    echo "Office Number"
    read user_location
    echo "Postcode"
    read user_postcode
    echo "Postal Address"
    read user_postal_address
    echo "Work: Mobile Phone"
    read user_work_mobile_phone
    echo "Home: Phone"
    read user_home_phone

    echo """
dn: uid=$username,ou=people,dc=$HOSTNAME,dc=$AVAHI_DOMAIN
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: $username
sn: $user_lastname
givenName: $user_firstname
cn: $user_firstname $user_lastname
displayName: $user_firstname
uidNumber: $USERS_UID
gidNumber: $USERS_GID
userPassword: $password
gecos: $user_firstname $user_lastname
loginShell: /bin/bash
homeDirectory: /home/$username
shadowExpire: -1
shadowFlag: 0
shadowWarning: 7
shadowMin: 8
shadowMax: 999999
shadowLastChange: 10877
mail: $username@$HOSTNAME.$AVAHI_DOMAIN
postalCode: $user_postcode
l: $user_postal_address
o: $user_org
mobile: $user_work_mobile_phone
homePhone: $user_home_phone
title: $user_title
postalAddress: $user_postal_address
initials: $user_initials
""" | tee ${TEMP_LDIF_OUTPUT_DIR}/users/frontend-$username.ldif

sudo ldapadd -x -D cn=admin,dc=$HOSTNAME,dc=$AVAHI_DOMAIN -W -f ${TEMP_LDIF_OUTPUT_DIR}/users/frontend-$username.ldif
echo "Testing Database for : $username"

ldapsearch -xLLL -b "dc=$HOSTNAME,dc=$AVAHI_DOMAIN" uid=$username sn givenName cn

