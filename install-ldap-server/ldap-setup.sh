#!/bin/sh
SCRIPT_PATH=${0%/*}
. $SCRIPT_PATH/lib/coloured_messages.sh

EXIT_SIGNAL=1
TEMP_LDIF_OUTPUT_DIR="/tmp/ldap-setup"
USERS_GID=10000
USERS_UID=1000

message "Ubuntu 10.04 LDAP Server Setup" "header"


message "remove previous configurations and database. [y/n]" "choice"
read pause
case $pause in
	"y" )
		message "removing old ldap database" "warning"
		for file in `sudo ls /var/lib/ldap/`; do sudo rm /var/lib/ldap/${file}; done
		sudo rm /etc/ldap/ldap.conf
		for file in `ls /etc/samba/smb.conf.pre-ldap.backup`; do sudo cp /etc/samba/$file /etc/samba/smb.conf; done
		;;
	"n")
		message "leaving old files alone"
		;;
esac


if [ -d ${TEMP_LDIF_OUTPUT_DIR} ]; then
	message "Remove previous ldif files ? " "choice"
	read pause
	case $pause in
		"y" )
			sudo rm $TEMP_LDIF_OUTPUT_DIR -rf
			;;
		"n" )
			message "leaving ldif files alone"
			;;
	esac
fi

message "building temporary storage " "header"
sudo mkdir ${TEMP_LDIF_OUTPUT_DIR} -p
sudo mkdir ${TEMP_LDIF_OUTPUT_DIR}/users -p
sudo mkdir ${TEMP_LDIF_OUTPUT_DIR}/groups -p

CURRENT_HOSTNAME=`hostname`

message "The Avahi Domain Name : " "choice"
message "usually 'local'"
read AVAHI_DOMAIN
message "What is the ServerName : " "choice"
message "This server is currently called : $CURRENT_HOSTNAME"
read HOSTNAME
message "Enter the password for the LDAP Admin :" "choice"
read ADMINPASSWORD


message "Changing Hostname & Static Hosts Associations"
message "hostname is now : $HOSTNAME"
sudo hostname $HOSTNAME
message "Current /etc/hosts state : "
cat /etc/hosts
sudo sed "s/\(127.0.1.1\) \($(hostname)\)/\1 $HOSTNAME/" -i /etc/hosts
message "changed to : "
cat /etc/hosts

message "Generating adminpassword SSHA hash."
ADMINPASSWORD_HASH=$(sudo slappasswd -s "$ADMINPASSWORD" -h {SSHA})
DOMAIN_DN="dc=$HOSTNAME,dc=$AVAHI_DOMAIN"
LDAP_ADMIN_DN="cn=admin,$DOMAIN_DN"
SERVER_FQDN="$HOSTNAME.$AVAHI_DOMAIN"

message "Generate config ? [y/n]" "choice"
read pause
case $pause in
	"y" )

echo """
BASE    $DOMAIN_DN
URI     ldap://ldap.$HOSTNAME.$AVAHI_DOMAIN ldap://ldap-master.${SERVER_FQDN}:666

suffix          "$DOMAIN_DN"
directory       "/var/lib/ldap"
rootdn          "$LDAP_ADMIN_DN"
rootpw          $ADMINPASSWORD_HASH

dbconfig set_cachesize 0 2097152 0
dbconfig set_lk_max_objects 1500
dbconfig set_lk_max_locks 1500
dbconfig set_lk_max_lockers 1500


index ou,cn,sn,mail,givenname           eq,pres,sub
index uidNumber,gidNumber,memberUid     eq,pres
index loginShell                        eq,pres
index uniqueMember                      eq,pres
index uid                               pres,sub,eq
index uid, memberUid                    eq
index displayName                       pres,sub,eq
index sambaSID                          eq
index sambaPrimaryGroupSID              eq
index sambaDomainName                   eq
index default                           sub

lastmod         on

access to attrs=userPassword,shadowLastChange
        by dn="${LDAP_ADMIN_DN}" write
        by anonymous auth
        by self write
        by * none

access to dn.base="" by * read

access to *
        by dn="$LDAP_ADMIN_DN" write
        by * read

""" | sudo tee -a /etc/ldap/ldap.conf
		;;
	"n")
		message "skipping config"
		;;
esac

message "LDAP Server Avahi Aliases" "Header"
sudo avahi-add-alias ldap-master.$HOSTNAME.$AVAHI_DOMAIN ldap.$HOSTNAME.$AVAHI_DOMAIN

message "Restarting LDAP Server" "header"
sudo service slapd restart

message "Insert Default Schemas ? [y/n]" "choice"
read pause
case $pause in
	"y" )
		message "LDAP Database Schema : Import Sane Defaults" "header"
		sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/cosine.ldif
		sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/nis.ldif
		sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/inetorgperson.ldif
		;;
	"n")
		message "skipping default schemas" "warning"
		;;
esac

message "Insert Backend ? [y/n]" "choice"
read pause
case $pause in
	"y" )

message "LDAP Database Schema : Backend Defaults" "header"
echo """
# Load dynamic backend modules
dn: cn=module,cn=config
objectClass: olcModuleList
cn: module
olcModulepath: /usr/lib/ldap
olcModuleload: back_hdb

# Database settings
dn: olcDatabase=hdb,cn=config
objectClass: olcDatabaseConfig
objectClass: olcHdbConfig
olcDatabase: {1}hdb
olcSuffix: $DOMAIN_DN
olcDbDirectory: /var/lib/ldap
olcRootDN: ${LDAP_ADMIN_DN}
olcRootPW: $ADMINPASSWORD
olcDbConfig: set_cachesize 0 2097152 0
olcDbConfig: set_lk_max_objects 1500
olcDbConfig: set_lk_max_locks 1500
olcDbConfig: set_lk_max_lockers 1500
olcDbIndex: objectClass eq
olcLastMod: TRUE
olcDbCheckpoint: 512 30
olcAccess: to attrs=userPassword by dn="$LDAP_ADMIN_DN" write by anonymous auth by self write by * none
olcAccess: to attrs=shadowLastChange by self write by * read
olcAccess: to dn.base="" by * read
olcAccess: to * by dn="$LDAP_ADMIN_DN" write by * read
""" | tee -a ${TEMP_LDIF_OUTPUT_DIR}/backend.ldif

		message "LDAP Schema : Inserting Backend Defaults"
		sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ${TEMP_LDIF_OUTPUT_DIR}/backend.ldif
		;;
	"n")
		message "skipping backend"
		;;
esac


message "Insert Frontend ? [y/n]" "choice"
read pause
case $pause in
	"y" )
message "LDAP Schema Frontend Data : Top Level Domain" "header"
echo """
dn: $DOMAIN_DN
objectClass: top
objectClass: dcObject
objectclass: organization
o: $HOSTNAME
dc: $HOSTNAME
description: LDAP Server
""" | tee -a ${TEMP_LDIF_OUTPUT_DIR}/frontend.ldif
message "press any key when ready..." "choice"
read pause

message "LDAP Schema Frontend Data : LDAP Admin Account" "header"
echo """
dn: $LDAP_ADMIN_DN
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
userPassword: $ADMINPASSWORD
""" | tee -a ${TEMP_LDIF_OUTPUT_DIR}/frontend.ldif

message "LDAP Schema Frontend Data : Base Users and Groups" "header"
echo """
# base tree
dn: ${DOMAIN_DN}
dc: ${HOSTNAME}
objectClass: domain
objectClass: domainRelatedObject
associatedDomain: ${SERVER_FQDN}

dn: ou=People,${DOMAIN_DN}
objectClass: organizationalUnit
objectclass: top
ou: People

dn: ou=Group,${DOMAIN_DN}
description: Container for user accounts
objectclass: organizationalUnit
objectclass: top
ou: Group

dn: ou=System Accounts,${DOMAIN_DN}
description: Container for System and Services privileged accounts
objectClass: organizationalUnit
ou: System Accounts

dn: ou=System Groups,${DOMAIN_DN}
ou: System Groups
objectClass: organizationalUnit
description: Container for System and Services privileged groups

dn: ou=Hosts,${DOMAIN_DN}
ou: Hosts
objectClass: organizationalUnit
description: Container for Samba machine accounts

dn: ou=Idmap,${DOMAIN_DN}
ou: Idmap
objectClass: organizationalUnit
description: Container for Samba Winbind ID mappings

dn: ou=Address Book,${DOMAIN_DN}
ou: Address Book
objectClass: organizationalUnit
description: Container for global address book entries

dn: ou=sudoers,${DOMAIN_DN}
ou: sudoers
objectClass: organizationalUnit
description: Container for sudo related entries

dn: cn=defaults,ou=sudoers,${DOMAIN_DN}
cn: defaults
objectClass: sudoRole
sudoOption: authenticate
description: Default options for sudo roles

dn: ou=dhcp,${DOMAIN_DN}
ou: dhcp
objectClass: organizationalUnit
description: Container for DHCP related entries

dn: ou=dns,${DOMAIN_DN}
ou: dns
objectClass: organizationalUnit
description: Container for DNS related entries

dn: ou=Password Policies,${DOMAIN_DN}
ou: Password Policies
objectClass: organizationalUnit
description: Container for OpenLDAP password policies

dn: cn=default,ou=Password Policies,${DOMAIN_DN}
cn: default
objectClass: pwdPolicy
objectClass: namedObject
pwdAttribute: userPassword

# System Accounts
dn: uid=Account Admin,ou=System Accounts,${DOMAIN_DN}
uid: Account Admin
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to administer all users, groups, machines and general accounts

dn: uid=nssldap,ou=System Accounts,${DOMAIN_DN}
uid: nssldap
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Unprivileged account which can be used by nss_ldap for when anonymous searches are disabled

dn: uid=MTA Admin,ou=System Accounts,${DOMAIN_DN}
uid: MTA Admin
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to administer email related attributes

dn: uid=DHCP Admin,ou=System Accounts,${DOMAIN_DN}
uid: DHCP Admin
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to administer DHCP related entries and attributes

dn: uid=DHCP Reader,ou=System Accounts,${DOMAIN_DN}
uid: DHCP Reader
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to read entries and attributes under ou=dhcp

dn: uid=DNS Admin,ou=System Accounts,${DOMAIN_DN}
uid: DNS Admin
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to administer DNS related entries and attributes

dn: uid=DNS Reader,ou=System Accounts,${DOMAIN_DN}
uid: DNS Reader
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to read entries and attributes under ou=dns

dn: uid=Sudo Admin,ou=System Accounts,${DOMAIN_DN}
uid: Sudo Admin
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to administer Sudo related entries and attributes

dn: uid=Address Book Admin,ou=System Accounts,${DOMAIN_DN}
uid: Address Book Admin
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to administer global Address Book related entries and attributes

dn: uid=LDAP Admin,ou=System Accounts,${DOMAIN_DN}
uid: LDAP Admin
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to administer all parts of the Directory

dn: uid=LDAP Replicator,ou=System Accounts,${DOMAIN_DN}
uid: LDAP Replicator
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used by consumer servers for replication

dn: uid=LDAP Monitor,ou=System Accounts,${DOMAIN_DN}
uid: LDAP Monitor
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to read cn=monitor entries

dn: uid=Idmap Admin,ou=System Accounts,${DOMAIN_DN}
uid: Idmap Admin
objectClass: account
objectClass: simpleSecurityObject
userPassword: ${ADMINPASSWORD}
description: Account used to administer Samba Winbind ID mapping related entries and attributes

# Groups associated with system accounts
dn: cn=LDAP Admins,ou=System Groups,${DOMAIN_DN}
cn: LDAP Admins
objectClass: groupOfNames
description: Members can administer all parts of the Directory
owner: uid=LDAP Admin,ou=System Accounts,${DOMAIN_DN}
member: uid=LDAP Admin,ou=System Accounts,${DOMAIN_DN}

dn: cn=Account Admins,ou=System Groups,${DOMAIN_DN}
cn: Account Admins
objectClass: groupOfNames
description: Members can administer all user, group and machine accounts
owner: uid=Account Admin,ou=System Accounts,${DOMAIN_DN}
member: uid=Account Admin,ou=System Accounts,${DOMAIN_DN}

dn: cn=Sudo Admins,ou=System Groups,${DOMAIN_DN}
cn: Sudo Admins
objectClass: groupOfNames
description: Members can administer ou=sudoers entries and attributes
owner: uid=Sudo Admin,ou=System Accounts,${DOMAIN_DN}
member: uid=Sudo Admin,ou=System Accounts,${DOMAIN_DN}

dn: cn=DNS Admins,ou=System Groups,${DOMAIN_DN}
cn: DNS Admins
objectClass: groupOfNames
description: Members can administer ou=DNS entries and attributes
owner: uid=DNS Admin,ou=System Accounts,${DOMAIN_DN}
member: uid=DNS Admin,ou=System Accounts,${DOMAIN_DN}

dn: cn=DNS Readers,ou=System Groups,${DOMAIN_DN}
cn: DNS Readers
objectClass: groupOfNames
description: Members can read entries and attributes under ou=dns
owner: uid=DNS Admin,ou=System Accounts,${DOMAIN_DN}
member: uid=DNS Reader,ou=System Accounts,${DOMAIN_DN}

dn: cn=DHCP Admins,ou=System Groups,${DOMAIN_DN}
cn: DHCP Admins
objectClass: groupOfNames
description: Members can administer ou=DHCP entries and attributes
owner: uid=DHCP Admin,ou=System Accounts,${DOMAIN_DN}
member: uid=DHCP Admin,ou=System Accounts,${DOMAIN_DN}

dn: cn=DHCP Readers,ou=System Groups,${DOMAIN_DN}
cn: DHCP Readers
objectClass: groupOfNames
description: Members can read entries and attributes under ou=dhcp
owner: uid=DHCP Admin,ou=System Accounts,${DOMAIN_DN}
member: uid=DHCP Reader,ou=System Accounts,${DOMAIN_DN}

dn: cn=Address Book Admins,ou=System Groups,${DOMAIN_DN}
cn: Address Book Admins
objectClass: groupOfNames
description: Members can administer ou=Address Book entries and attributes
owner: uid=Address Book Admin,ou=System Accounts,${DOMAIN_DN}
member: uid=Address Book Admin,ou=System Accounts,${DOMAIN_DN}

dn: cn=LDAP Replicators,ou=System Groups,${DOMAIN_DN}
cn: LDAP Replicators
objectClass: groupOfNames
description: Members can be used for syncrepl replication
owner: uid=LDAP Replicator,ou=System Accounts,${DOMAIN_DN}
member: uid=LDAP Replicator,ou=System Accounts,${DOMAIN_DN}

dn: cn=MTA Admins,ou=System Groups,${DOMAIN_DN}
cn: MTA Admins
objectClass: groupOfNames
description: Members can administer email related attributes
owner: uid=MTA Admin,ou=System Accounts,${DOMAIN_DN}
member: uid=MTA Admin,ou=System Accounts,${DOMAIN_DN}

dn: cn=LDAP Monitors,ou=System Groups,${DOMAIN_DN}
cn: LDAP Monitors
objectClass: groupOfNames
description: Members can read the cn=monitor backend
owner: uid=LDAP Monitor,ou=System Accounts,${DOMAIN_DN}
member: uid=LDAP Monitor,ou=System Accounts,${DOMAIN_DN}

dn: cn=Idmap Admins,ou=System Groups,${DOMAIN_DN}
cn: Idmap Admins
objectClass: groupOfNames
description: Members can administer ou=Idmap entries and attributes
owner: uid=Idmap Admin,ou=System Accounts,${DOMAIN_DN}
member: uid=Idmap Admin,ou=System Accounts,${DOMAIN_DN}

""" | tee -a $TEMP_LDIF_OUTPUT_DIR/frontend.ldif

		## Until we recieve a exit signal from zenity, keep asking for user account details
		message "Adding frontend data "
		message "sudo ldapadd -x -D ${LDAP_ADMIN_DN} -w ${ADMINPASSWORD} -f ${TEMP_LDIF_OUTPUT_DIR}/frontend.ldif"
		read paused
		sudo ldapadd -x -D ${LDAP_ADMIN_DN} -w ${ADMINPASSWORD} -f ${TEMP_LDIF_OUTPUT_DIR}/frontend.ldif
		;;
	"n")
		message "skipping front end data"
		;;
esac


message "Scan Preseed Data ? [y/n]" "choice"
read pause
case $pause in
	"y" )

		message "LDAP Schema Frontend Data : Users" "header"
		message "PRESEED : LDAP USERS" "header"
		LDAP_PRESEED_USERS="${SCRIPT_PATH}/ldap-preseed/users"
		message $LDAP_PRESEED_USERS

		for file in `ls ${LDAP_PRESEED_USERS}/*`;do
			message "processing : ${file}"
			sudo ldapadd -x -D $LDAP_ADMIN_DN -W -f ${file}
		done
		;;
	"n")
		message "skipping preseed"
		;;
esac

message "Manually Add Some Users ? [y/n]" "choice"
read ZENITYSIGNAL

while [ "$ZENITYSIGNAL" -ne "N" ]; do
    sudo sh ./adduser.sh $HOSTNAME $AVAHI_DOMAIN $USERS_GID $USERS_UID

    USERS_UID=`expr $USERS_UID+1`
    echo "Add More Users?"
    read ZENITYSIGNAL
    if [ "$ZENITYSIGNAL" -eq "N" ]; then
        break
    fi
done

message "Restarting LDAP Server" "header"
sudo service slapd stop
sudo service slapd start

