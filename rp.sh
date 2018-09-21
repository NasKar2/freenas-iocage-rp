#!/bin/sh
# Build an iocage jail under FreeNAS 11.1 using the current release of Nextcloud 13
# https://github.com/danb35/freenas-iocage-rp

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi

# Initialize defaults
JAIL_IP=""
DEFAULT_GW_IP=""
INTERFACE=""
VNET="off"
POOL_PATH=""
JAIL_NAME="rp"
TIME_ZONE=""
HOST_NAME=""
DB_PATH=""
FILES_PATH=""
PORTS_PATH=""
STANDALONE_CERT=0
DNS_CERT=0
TEST_CERT="--staging"
TYPE_CERT="--webroot"
C_NAME="US"
ST_NAME=""
L_NAME=""
O_NAME=""
OU_NAME=""
EMAIL_NAME=""
NO_SSL=""

SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "$SCRIPT")
. $SCRIPTPATH/rp-config
CONFIGS_PATH=$SCRIPTPATH/configs
DB_ROOT_PASSWORD=$(openssl rand -base64 16)
DB_PASSWORD=$(openssl rand -base64 16)
ADMIN_PASSWORD=$(openssl rand -base64 12)
RELEASE=$(freebsd-version | sed "s/STABLE/RELEASE/g")

# Check for rp-config and set configuration
if ! [ -e $SCRIPTPATH/rp-config ]; then
  echo "$SCRIPTPATH/rp-config must exist."
  exit 1
fi

# Check that necessary variables were set by rp-config
if [ -z $JAIL_IP ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z $DEFAULT_GW_IP ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi
if [ -z $INTERFACE ]; then
  echo 'Configuration error: INTERFACE must be set'
  exit 1
fi
if [ -z $POOL_PATH ]; then
  echo 'Configuration error: POOL_PATH must be set'
  exit 1
fi
if [ -z $TIME_ZONE ]; then
  echo 'Configuration error: TIME_ZONE must be set'
  exit 1
fi
if [ -z $HOST_NAME ]; then
  echo 'Configuration error: HOST_NAME must be set'
  exit 1
fi
if [ $STANDALONE_CERT -eq 0 ] && [ $DNS_CERT -eq 0 ]; then
  echo 'Configuration error: Either STANDALONE_CERT or DNS_CERT'
  echo 'must be set to 1.'
  exit 1
fi
if [ $DNS_CERT -eq 1 ] && ! [ -x $CONFIGS_PATH/acme_dns_issue.sh ]; then
  echo 'If DNS_CERT is set to 1, configs/acme_dns_issue.sh must exist'
  echo 'and be executable.'
  exit 1
fi

# If DB_PATH, FILES_PATH, and PORTS_PATH weren't set in rp-config, set them
#if [ -z $DB_PATH ]; then
#  DB_PATH="${POOL_PATH}/db"
#fi
#if [ -z $FILES_PATH ]; then
#  FILES_PATH="${POOL_PATH}/files"
#fi
if [ -z $PORTS_PATH ]; then
  PORTS_PATH="${POOL_PATH}/portsnap"
fi

# Sanity check DB_PATH, FILES_PATH, and PORTS_PATH -- they all have to be different,
# and can't be the same as POOL_PATH
#if [ "${DB_PATH}" = "${FILES_PATH}" ] || [ "${FILES_PATH}" = "${PORTS_PATH}" ] || [ "${PORTS_PATH}" = "${DB_PATH}" ]
#then
#  echo "DB_PATH, FILES_PATH, and PORTS_PATH must all be different!"
#  exit 1
#fi

#if [ "${DB_PATH}" = "${POOL_PATH}" ] || [ "${FILES_PATH}" = "${POOL_PATH}" ] || [ "${PORTS_PATH}" = "${POOL_PATH}" ] 
#then
#  echo "DB_PATH, FILES_PATH, and PORTS_PATH must all be different"
#  echo "from POOL_PATH!"
#  exit 1
#fi

# Make sure DB_PATH is empty -- if not, MariaDB will choke
#if [ "$(ls -A $DB_PATH)" ]; then
#  echo "$DB_PATH is not empty!"
#  echo "DB_PATH must be empty, otherwise this script will break your existing database."
#  exit 1
#fi
#openssl parameters
if [ -z $C_NAME ]; then
echo 'Configuration error: C_NAME must be set'
exit 1
fi
    
if [ -z $ST_NAME ]; then
echo 'Configuration error: ST_NAME must be set'
exit 1
fi
        
if [ -z $L_NAME ]; then
echo 'Configuration error: L_NAME must be set'
exit 1
fi
            
if [ -z $O_NAME ]; then
echo 'Configuration error: O_NAME must be set'
exit 1
fi
                
if [ -z $OU_NAME ]; then
echo 'Configuration error: OU_NAME must be set'
exit 1
fi

if [ -z $EMAIL_NAME ]; then
echo 'Configuration error: OU_NAME must be set'
exit 1
fi
echo $NO_SSL
if [ -z $NO_SSL ]; then
NO_SSL="no"
fi 

#echo '{"pkgs":["nano","rsync","openssl","curl","sudo","php72-phar","py27-certbot","nginx","mariadb102-server","redis","php72-ctype","php72-dom","php72-gd","php72-iconv","php72-json","php72-mbstring","php72-posix","php72-simplexml","","php72-xmlreader","php72-xmlwriter","php72-zip","php72-zlib","php72-pdo_mysql","php72-hash","php72-xml","php72-session","php72-mysqli","php72-wddx","php72-xsl","php72-filter","php72-curl","php72-fileinfo","php72-bz2","php72-intl","php72-openssl","php72-ldap","php72-ftp","php72-imap","php72-exif","php72-gmp","php72-memcache","php72-opcache","php72-pcntl","php72","mod_php72","bash","p5-Locale-gettext","help2man","texinfo","m4","autoconf","socat","git","perl5.28"]}' > /tmp/pkg.json
echo '{"pkgs":["nano","openssl","py27-certbot","nginx","git","python"]}' > /tmp/pkg.json
iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r $RELEASE ip4_addr="${INTERFACE}|${JAIL_IP}/24" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"

rm /tmp/pkg.json

iocage exec ${JAIL_NAME} mkdir -p /mnt/configs

iocage fstab -a ${JAIL_NAME} ${CONFIGS_PATH} /mnt/configs nullfs rw 0 0

#iocage exec ${JAIL_NAME} chsh -s /usr/local/bin/bash root

iocage exec ${JAIL_NAME} sysrc nginx_enable="YES"

#iocage exec ${JAIL_NAME} -- mkdir -p /usr/local/etc/nginx/ssl/

iocage exec ${JAIL_NAME} 'echo 'DEFAULT_VERSIONS+=ssl=openssl' >> /etc/make.conf'
#iocage exec ${JAIL_NAME} portsnap fetch extract
#iocage exec ${JAIL_NAME} make -C /usr/ports/databases/pecl-redis clean install BATCH=yes
#iocage exec ${JAIL_NAME} make -C /usr/ports/devel/pecl-APCu clean install BATCH=yes
  
# Copy and edit pre-written config files

if [ $NO_SSL = "yes" ]; then
   iocage exec ${JAIL_NAME} cp -f /mnt/configs/nginx.basic.conf /usr/local/etc/nginx/nginx.conf
   echo "NO_SSL=${NO_SSL}"
else
   iocage exec ${JAIL_NAME} mkdir -p /usr/local/etc/nginx/ssl/
   echo "make directory /usr/local/etc/nginx/ssl/"
   iocage exec ${JAIL_NAME} -- openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /usr/local/etc/nginx/ssl/nginx-selfsigned.key -out /usr/local/etc/nginx/ssl/nginx-selfsigned.crt -subj "/C=${C_NAME}/ST=$P{ST_NAME}/L=${L_NAME}/O=${O_NAME}/OU={OU_NAME}/CN={HOST_NAME}"
   echo "openssl key generated"
   iocage exec ${JAIL_NAME} -- openssl dhparam -out /usr/local/etc/nginx/ssl/dhparam.pem 2048 
   echo "dhparam done"
   iocage exec ${JAIL_NAME} cp -f /mnt/configs/nginx.conf /usr/local/etc/nginx/nginx.conf
#   iocage exec ${JAIL_NAME} cp -f /usr/local/etc/nginx/nginx.conf-dist /usr/local/etc/nginx/nginx.conf

fi

iocage exec ${JAIL_NAME} cp -f /mnt/configs/proxy_setup.conf /usr/local/etc/nginx/proxy_setup.conf
iocage exec ${JAIL_NAME} cp -f /mnt/configs/ssl_common.conf /usr/local/etc/nginx/ssl_common.conf
iocage exec ${JAIL_NAME} sed -i '' "s/yourhostnamehere/${HOST_NAME}/" /usr/local/etc/nginx/nginx.conf
iocage exec ${JAIL_NAME} sed -i '' "s/youripaddress/${JAIL_IP}/" /usr/local/etc/nginx/nginx.conf
iocage exec ${JAIL_NAME} sed -i '' "s/yourhostnamehere/${HOST_NAME}/" /usr/local/etc/nginx/ssl_common.conf
#iocage exec ${JAIL_NAME} sed -i '' "s/#skip-networking/skip-networking/" /var/db/mysql/my.cnf
#iocage exec ${JAIL_NAME} sed -i '' "s|mytimezone|${TIME_ZONE}|" /usr/local/etc/php.ini
#iocage exec ${JAIL_NAME} openssl dhparam -out /usr/local/etc/pki/tls/private/dhparams_4096.pem 4096
iocage restart ${JAIL_NAME}

if [ $NO_SSL = "yes" ]; then
   echo "NO_SSL check yes"
else
   #iocage exec ${JAIL_NAME} -- certbot certonly --debug --webroot -w /usr/local/www -d ${HOST_NAME} --agree-tos -m ${EMAIL_NAME} --no-eff-email
        if [ TYPE_CERT = "--webroot" ]; then
            iocage exec ${JAIL_NAME} -- certbot certonly ${TEST_CERT} --webroot -w /usr/local/www -d ${HOST_NAME} --agree-tos -m ${EMAIL_NAME} --no-eff-email
        else
            iocage exec ${JAIL_NAME} -- certbot certonly ${TEST_CERT} --standalone -w /usr/local/www -d ${HOST_NAME} --agree-tos -m ${EMAIL_NAME} --no-eff-email
        fi
   echo "certbot done"
fi

# If standalone mode was used to issue certificate, reissue using webroot
#if [ $STANDALONE_CERT -eq 1 ]; then
#  iocage exec ${JAIL_NAME} /root/.acme.sh/acme.sh --issue ${TEST_CERT} --home "/root/.acme.sh" -d ${HOST_NAME} -w /usr/local/www/apache24/data -k 4096 --fullchain-file /usr/local/etc/pki/tls/certs/fullchain.pem --key-file /usr/local/etc/pki/tls/private/privkey.pem --reloadcmd "service apache24 reload"
#iocage exec ${JAIL_NAME} /root/.acme.sh/acme.sh --issue ${TEST_CERT} --home "/root/.acme.sh" -d ${HOST_NAME} -w /usr/local/www -k 4096 --fullchain-file /usr/local/etc/fullchain.pem --key-file /usr/local/etc/pki/tls/private/privkey.pem --reloadcmd "service nginx reload"

#fi

iocage exec ${JAIL_NAME} service nginx restart

# add media group to www user
#iocage exec ${JAIL_NAME} pw groupadd -n media -g 8675309
#iocage exec ${JAIL_NAME} pw groupmod media -m www
#iocage restart ${JAIL_NAME} 


# Done!
echo "##########################################################################"
echo "Installation complete!"
#if [ $NO_SSL = "yes" ]; then
 #  echo "Using your web browser, go to https://${JAIL_IP}/nextcloud to log in"
#else
#   echo "Using your web browser, go to https://${HOST_NAME}/nextcloud to log in"
#fi

