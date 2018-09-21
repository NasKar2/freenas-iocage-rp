# freenas-iocage-nextcloud
Script to create an iocage jail on FreeNAS for a reversse proxy using nginx and  Let's Encrypt

## Status
This script has been tested on FreeNAS 11.1-U2 and appears to be working without issue.  It is known to NOT work on 11.1-U3 or 11.1-U4 out of the box. 11.1-U3 has a version of iocage with a bug in the jail creation script. This can be fixed by using the following commands.

```
cd /tmp
git clone --recursive https://github.com/iocage/iocage
cp -R iocage/iocage/lib/ /usr/local/lib/python3.6/site-packages/iocage/lib
```
## Usage

### Prerequisites
Open port 80 and 443 in your router for the ip specified in the config file below.

### Installation
Download the repository to a convenient directory on your FreeNAS system by running `git clone https://github.com/NasKar2/freenas-iocage-rp.git`.  Then change into the new directory and create a file called `rp-config`.  It should look like this:
```
JAIL_IP="192.168.1.199" #ip address of iocage jail
DEFAULT_GW_IP="192.168.1.1"
INTERFACE="igb0"
VNET="off"
POOL_PATH="/mnt/v1" #your pool
JAIL_NAME="rp" #name of iocage jail to be created
TIME_ZONE="America/New_York" # See http://php.net/manual/en/timezones.php
HOST_NAME="YOUR_FQDN"
STANDALONE_CERT=0
DNS_CERT=0
TEST_CERT="--staging"
TYPE_CERT="--webroot"
C_NAME="US"
ST_NAME="yourstate"
L_NAME="yourcity"
O_NAME="FreeNAS"
OU_NAME="FreeNAS_IT"
EMAIL_NAME="youremail@gmail.com"
NO_SSL=""

```
Many of the options are self-explanatory, and all should be adjusted to suit your needs.  JAIL_IP and DEFAULT_GW_IP are the IP address and default gateway, respectively, for your jail.  INTERFACE is the network interface that your FreeNAS server is actually using.  If you have multiple interfaces, run `ifconfig` and see which one has an IP address, and enter that one here. If you want to use a virtual non-shared IP, pick a unused name as your interface and set VNET to ''on''  POOL_PATH is the path for your data pool, on which the Nextcloud user data and MariaDB database will be stored.  JAIL_NAME is the name of the jail, and wouldn't ordinarily need to be changed.  If you don't specify it in nextcloud-config, JAIL_NAME will default to "nextcloud".  TIME_ZONE is the time zone of your location, as PHP sees it--see the [PHP manual](http://php.net/manual/en/timezones.php) for a list of all valid time zones.

HOST_NAME is the fully-qualified domain name you want to assign to your installation.  You must own (or at least control) this domain, because Let's Encrypt will test that control.  STANDALONE_CERT and DNS_CERT control which validation method Let's Encrypt will use to do this.  If HOST_NAME is accessible to the outside world--that is, you have ports 80 and 443 (at least) forwarded to your jail, so that if an outside user browses to http://HOST_NAME/, he'll reach your jail--set STANDALONE_CERT to 1, and DNS_CERT to 0.

DB_PATH, FILES_PATH, and PORTS_PATH can optionally be set to individual paths for your MariaDB database, your Nextcloud files, and your FreeBSD ports collection.  If not set, they'll default to $POOL_PATH/db, $POOL_PATH/files, and $POOL_PATH/portsnap, respectively.  These do not need to be set in nextcloud-config, and **should not be set** unless you want the MariaDB database, your Nextcloud files, and/or your ports collection to be in a non-standard location.

Finally, TEST_CERT is a flag to issue test certificates from Let's Encrypt.  They'll run through the same issuance process in the same, but will come from an un-trusted certificate authority (so you'll get a warning when you first visit your site).  For test purposes, I recommend you set this to "--staging" as above, otherwise the [Let's Encrypt rate limits](https://letsencrypt.org/docs/rate-limits/) may prevent issuing the cert when you most want it.  Once you've confirmed that everything is working properly, you can set TEST_CERT to "".  Unless you set TEST_CERT to "" in nextcloud-config, it will default to "--staging".

It's also helpful if HOST_NAME resolves to your jail from **inside** your network.  You'll probably need to configure this on your router.  If it doesn't, you'll still be able to reach your reverse proxy installation via the jail's IP address, but you'll get certificate errors that way.
To automate the generation of an openssl certificate add the options for C_NAME your country of origin, ST_NAME your state, L_NAME your city, O_name is your orgainization, OU_NAME is your department, and finally EMAIL_NAME is your email address.
Set TYPE_CERT to "--webroot" if not it will default to "--standalone".  Set NO_SSL="yes" if you don't want to install with ssl

### Execution
Once you've downloaded the script, prepared the configuration file, run this script (`./rp.sh`).  The script will run for several minutes.  When it finishes, your jail will be created,

### To Do
Currently not working
This script has been tested on my system, in Standalone mode only, and everything seems to be working properly.  Further testing is, of course, always appreciated.

I'd also appreciate any suggestions (or pull requests) to improve the various config files I'm using.  Most of them are adapted from the default configuration files that ship with the software in question, and have only been lightly edited to work in this application.  But if there are changes to settings or organization that could improve performance or reliability, I'd like to hear about them.
