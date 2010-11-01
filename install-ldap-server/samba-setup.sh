#!/bin/sh
# Install Samba & utilities
sudo cp /etc/samba/smb.conf.pre-ldap.${date +%d.%m.%Y-%H%M%S}.backup

ZENITYSIGNAL_EXIT=1
# seetup the ADMIN password

echo "[ LDAP SAMBA INSTALLER ] :>avahi domain name (usually 'local')"
read AVAHI_DOMAIN

echo "[ LDAP SAMBA INSTALLER ] :>server hostname"
read HOSTNAME

echo "[ LDAP SAMBA INSTALLER ] :>LDAP Administrator Password"
read ADMINPASSWORD

echo "[ LDAP SAMBA INSTALLER ] :>Mapped Drive Letter for Users Home Directory on Domain Clients "
read DRIVEMAP

echo """
[global]
    # Domain name ..
    workgroup = $HOSTNAME
    # Server name - as seen by Windows PCs ..
    netbios name = $HOSTNAME
    # Be a PDC ..
    domain logons = Yes
    domain master = Yes
    # Be a WINS server ..
    wins support = true

    obey pam restrictions = Yes
    dns proxy = No
    os level = 35
    log file = /var/log/samba/log.%m
    max log size = 1000
    syslog = 0
    panic action = /usr/share/samba/panic-action %d
    pam password change = Yes

    # Allows users on WinXP PCs to change their password when they press Ctrl-Alt-Del
    unix password sync = no
    ldap passwd sync = yes

    # Printing from PCs will go via CUPS ..
    load printers = yes
    printing = cups
    printcap name = cups

    # Use LDAP for Samba user accounts and groups ..
    passdb backend = ldapsam:ldap://localhost

    # This must match init.ldif ..
    ldap suffix = dc=$HOSTNAME,dc=$AVAHI_DOMAIN
    # The password for cn=admin MUST be stored in /etc/samba/secrets.tdb
    # This is done by running 'sudo smbpasswd -w'.
    ldap admin dn = cn=admin,dc=$HOSTNAME,dc=$AVAHI_DOMAIN

    # 4 OUs that Samba uses when creating user accounts, computer accounts, etc.
    # (Because we are using smbldap-tools, call them 'Users', 'Computers', etc.)
    ldap machine suffix = ou=Computers
    ldap user suffix = ou=Users
    ldap group suffix = ou=Groups
    ldap idmap suffix = ou=Idmap
    # Samba and LDAP server are on the same server in this example.
    ldap ssl = no

    # Scripts for Samba to use if it creates users, groups, etc.
    add user script = /usr/sbin/smbldap-useradd -m '%u'
    delete user script = /usr/sbin/smbldap-userdel %u
    add group script = /usr/sbin/smbldap-groupadd -p '%g'
    delete group script = /usr/sbin/smbldap-groupdel '%g'
    add user to group script = /usr/sbin/smbldap-groupmod -m '%u' '%g'
    delete user from group script = /usr/sbin/smbldap-groupmod -x '%u' '%g'
    set primary group script = /usr/sbin/smbldap-usermod -g '%g' '%u'

    # Script that Samba users when a PC joins the domain ..
    # (when changing 'Computer Properties' on the PC)
    add machine script = /usr/sbin/smbldap-useradd -w '%u'

    # Values used when a new user is created ..
    # (Note: '%L' does not work properly with smbldap-tools 0.9.4-1)
    logon drive = "$DRIVEMAP"
    logon home = "."
    logon path = "."
    logon script = allusers.bat


    # This is required for Windows XP client ..
    server signing = auto
    server schannel = Auto

[homes]
    comment = Home Directories
    valid users = %S
    read only = No
    browseable = No

[netlogon]
    comment = Network Logon Service
    path = /var/lib/samba/netlogon
    admin users = root
    guest ok = Yes
    browseable = No
    logon script = allusers.bat

[Profiles]
    comment = Roaming Profile Share
    # would probably change this to elsewhere in a production system ..
    path = /var/lib/samba/profiles
    read only = No
    profile acls = Yes
    browsable = No

[printers]
    comment = All Printers
    path = /var/spool/samba
    use client driver = Yes
    create mask = 0600
    guest ok = Yes
    printable = Yes
    browseable = No
    public = yes
    writable = yes
    admin users = root
    write list = root

[print$]
    comment = Printer Drivers Share
    path = /var/lib/samba/printers
    write list = root
    create mask = 0664
    directory mask = 0775
    admin users = root

[shared]
    writeable = yes
    path = /var/lib/samba/shared
    public = yes
    browseable = yes


[archive]
    path = /exports/archive
    browseable = yes
    create mask = 755
    directory mask = 755
    read only = no

""" | sudo tee /etc/samba/smb.conf

echo "[ LDAP SAMBA INSTALLER ] :>saving Administrator Password"
sudo smbpasswd -W -U admin -w $ADMINPASSWORD

# restart samba
echo "[ LDAP SAMBA INSTALLER ] :>Restarting Samba Service"
sudo service smbd stop
sudo service smbd start
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

# test that samba is running
echo "[ LDAP SAMBA INSTALLER ] :>Testing Samba Service"
sudo smbclient -L localhost
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

echo "[ LDAP SAMBA INSTALLER ] :>Creating Profile & NetLogin Directories"
# Create Profile & NetLogin Directories
sudo mkdir -v -m 777 /var/lib/samba/profiles
sudo mkdir -v -p -m 777 /var/lib/samba/netlogon
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

# Add Samba Schemas to LDAP Data base
echo "[ LDAP SAMBA INSTALLER ] :>Adding Samba Schemas to LDAP Data base"
sudo cp /usr/share/doc/samba-doc/examples/LDAP/samba.schema.gz /etc/ldap/schema/
sudo rm /etc/ldap/schema/samba.schema -f
sudo gzip -d /etc/ldap/schema/samba.schema.gz
echo """
include /etc/ldap/schema/core.schema
include /etc/ldap/schema/collective.schema
include /etc/ldap/schema/corba.schema
include /etc/ldap/schema/cosine.schema
include /etc/ldap/schema/duaconf.schema
include /etc/ldap/schema/dyngroup.schema
include /etc/ldap/schema/inetorgperson.schema
include /etc/ldap/schema/java.schema
include /etc/ldap/schema/misc.schema
include /etc/ldap/schema/nis.schema
include /etc/ldap/schema/openldap.schema
include /etc/ldap/schema/ppolicy.schema
include /etc/ldap/schema/samba.schema
""" | sudo tee ./schema_convert.conf
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

echo "[ LDAP SAMBA INSTALLER ] :>Converting schema to cn=config..."
sudo rm ./cn=* -rf
slapcat -f ./schema_convert.conf -F ./ -n0 -s "cn={12}samba,cn=schema,cn=config" > ./cn=samba.ldif
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

#Edit the result
echo "[ LDAP SAMBA INSTALLER ] :>removing superfluous entries"
sudo sed "s/dn: cn={12}samba,cn=schema,cn=config/dn: cn=samba,cn=schema,cn=config/" -i ./cn\=samba.ldif
sudo sed "s/cn: {12}samba/cn: samba/" -i ./cn\=samba.ldif

sudo sed "s/structuralObjectClass: olcSchemaConfig/ /" -i ./cn\=samba.ldif
sudo sed "s/entryUUID:.*$/ /" -i ./cn\=samba.ldif
sudo sed "s/creatorsName: cn=config/ /" -i ./cn\=samba.ldif
sudo sed "s/createTimestamp:.*/ /" -i ./cn\=samba.ldif
sudo sed "s/entryCSN:.*/ /" -i ./cn\=samba.ldif
sudo sed "s/modifiersName: cn=config/ /" -i ./cn\=samba.ldif
sudo sed "s/modifyTimestamp:.*/ /" -i ./cn\=samba.ldif

echo "[ LDAP SAMBA INSTALLER ] :>inserting into LDAP database"
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ./cn\=samba.ldif
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

# Unpack the samba-ldap-tools (we downloaded this earlier)
echo "[ LDAP SAMBA INSTALLER ] :>unpacking samba tools"
sudo rm /usr/share/doc/smbldap-tools/configure.pl
sudo gzip -d /usr/share/doc/smbldap-tools/configure.pl.gz
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

echo """
 Now we are going to execute a perl
 script which will set up samba for us.
 For almost every prompt you should just
 press Enter.

 There are a few of exceptions however.

 1. When asked for "logon home" and
    "logon path" enter a "." (fullstop)
    and nothing else.
 2. When asked for a password
    (ldap master/slave bind password)
    use the password for the "admin"
    account that you entered earlier.

  #######################
  ##      Remember     ##
  #######################

  Leave the default value for
  everything else!
"""

sudo perl /usr/share/doc/smbldap-tools/configure.pl
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

#Now that the script has created our configuration, we can use it to populate the server;
echo "[ LDAP SAMBA INSTALLER ] :>populating server"
sudo smbldap-populate
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

sudo service slapd stop
echo "[ LDAP SAMBA INSTALLER ] :>indexing LDAP"
sudo slapindex
echo "[ LDAP SAMBA INSTALLER ] :>changing ownership of /var/lib/ldap/* to user: openldap, group: openldap"
sudo chown openldap:openldap /var/lib/ldap/ -R
for file in $(sudo ls /var/lib/ldap/); do sudo chown openldap:openldap /var/lib/ldap/$file; done;
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

sudo service slapd start

#Make "root" the domain adminstrator;
echo "[ LDAP SAMBA INSTALLER ] :>Making root the domain adminstrator"
sudo smbldap-groupmod -m 'root' 'Administrators'
echo "[ LDAP SAMBA INSTALLER ] :> <<<< -- paused -- >>>>"
read pause

# Now, we need to allow clients to authenticate via LDAP. To do this we need to install a package.
echo "[ LDAP SAMBA INSTALLER ] :>installing client authentication modules..."
sudo apt-get --yes install ldap-auth-client

echo "[ LDAP SAMBA INSTALLER ] :>Tell PAM and the Name Service Switch service to use LDAP for authentication;"
sudo auth-client-config -t nss -p lac_ldap
sudo pam-auth-update ldap

echo "[ LDAP SAMBA INSTALLER ] :>Done!."
echo "[ LDAP SAMBA INSTALLER ] :>1. You can add users with the following syntax : "
echo "[ LDAP SAMBA INSTALLER ] :>   sudo smbldap-useradd -a -m -P username"
echo "[ LDAP SAMBA INSTALLER ] :>2. search for them with : "
echo "[ LDAP SAMBA INSTALLER ] :>""   ldapsearch -xLLL -b "dc=$HOSTNAME,dc=$AVAHI_DOMAIN" uid=username"""

