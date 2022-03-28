#!/bin/bash


#########################################################################
# cloudflare functions
#########################################################################
function check_required_cloudflare_vars (){

local EXIT_FLAG=0
if [ -z ${CLOUDFLARE_DNS_TOKEN+x} ]
then
  echo "CLOUDFLARE_DNS_TOKEN is not set. This is required to use Cloudflare DNS authentication for certbot."
  EXIT_FLAG=1
fi

if [ -z ${CLOUDFLARE_DNS_EMAIL+x} ]
then
  echo "CLOUDFLARE_DNS_EMAIL is not set. This is required to use Cloudflare DNS authentication for certbot."
  EXIT_FLAG=1
fi

return $EXIT_FLAG
}

function write_cloudflare_ini (){

  check_required_cloudflare_vars
  if [ $? = 1 ]
  then
    echo "Exiting in write_cloudflare_ini because of missing required ENV vars"
    exit 1
  fi
  echo "dns_cloudflare_api_token = ${CLOUDFLARE_DNS_TOKEN}" > /opt/certbot/cloudflare.ini
  chmod 600 /opt/certbot/cloudflare.ini

}

function get_cert_for_domain () {
  local _DOMAIN=$1
  echo "Going to request SSL certificates for $_DOMAIN and dry run is $DRY_RUN"

  local _CMD="certbot certonly --agree-tos --dns-cloudflare --dns-cloudflare-credentials /opt/certbot/cloudflare.ini -d $_DOMAIN -m $CLOUDFLARE_DNS_EMAIL"

  if [ -z ${DRY_RUN+x} ] and [ "$2" = "DRY_RUN" ] 
  then
    local CMD="$_CMD --dry-run"
  else
    local CMD=$_CMD
  fi

  echo $CMD

  if [ ! -d /etc/letsencrypt/live/${_DOMAIN} ]
  then
        $CMD
  else
  echo "Certificate directory for ${_DOMAIN} found. Cowardly refusing to  request a new certificate."
  echo "Run /opt/certbot/renew.sh instead if you wish to check and renew expiring certificates."
  fi
}


########################################################################################
# s3cmd functions
#########################################################################################

function check_required_s3cmd_vars (){
  MISSING_VARS=0

  if [ -z ${S3CMD_ACCESS_KEY+x} ]
  then
    echo "S3CMD_ACCESS_KEY is a requirend env variable but is missing";
    MISSING_VARS=1
  fi

  if [ -z ${S3CMD_SECRET_KEY+x} ]
  then
    echo "S3CMD_SECRET_KEY is a requirend env variable but is missing";
    MISSING_VARS=1
  fi

 if [ -z ${BACKUP_FILENAME_PREFIX+x} ]
  then
    echo "S3CMD_SECRET_KEY is a requirend env variable but is missing";
    MISSING_VARS=1
  fi


  return $MISSING_VARS
}

function write_s3cmd_config () {
  cat << EOF > /root/.s3cfg
[default]
encoding = UTF-8
access_key = $S3CMD_ACCESS_KEY
secret_key = $S3CMD_SECRET_KEY
host_base = abakuscloudstore.fi-hel2.upcloudobjects.com
host_bucket = %(bucket).abakuscloudstore.fi-hel2.upcloudobjects.com
website_endpoint = https://abakuscloudstore.fi-hel2.upcloudobjects.com/
check_ssl_certificate = True
check_ssl_hostname = True
gpg_command = /usr/bin/gpg
gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_passphrase = ${S3CMD_GPG_PASSPHASE}
EOF
}

function save_letsencrypt_folder_to_s3 (){
  local _BACKUP_FILENAME_PREFIX=$1
  echo "Got $_BACKUP_FILENAME_PREFIX to use for letsencrypt backup name"
  local _BACKUP_FILE="${_BACKUP_FILENAME_PREFIX}-$(date +'%Y-%m-%d_%H%M%S').tar.gz"
  tar -czf /backups/letsencrypt/$_BACKUP_FILE /etc/letsencrypt
  echo "Uploading $_BACKUP_FILE to AbakusCloud s3://letsencrypt"
  s3cmd put /backups/letsencrypt/$_BACKUP_FILE s3://letsencrypt 
}

function restore_letsencrypt_folder_from_s3 (){

  ###
  # This is coded to restore always the latest newest backup.
  ##

  local _BACKUP_FILENAME_PREFIX=$1
  echo "Got $_BACKUP_FILENAME_PREFIX to use for letsencrypt backup name"

  local _NEWEST_BACKUP=`s3cmd ls s3://letsencrypt | grep "${_BACKUP_FILENAME_PREFIX}-"  | awk -e '{print $4}' | sort | tail -1`
  local  _NEWEST_BACKUP_FILENAME=${_NEWEST_BACKUP#s3://letsencrypt/}
  echo $_NEWEST_BACKUP
  echo $_NEWEST_BACKUP_FILENAME
  local BACKUP_FULL_PATH="/backups/letsencrypt/${_NEWEST_BACKUP_FILENAME}"

  echo "resotre_letsencrypt_folder_from_s3: Entered /backups/letsencrupt"
  cd /backups/letsencrypt
  s3cmd get $_NEWEST_BACKUP
  cd /root

  #rm -rf /backups/letsencrypt
  cp -ar /etc/letsencrypt /etc/letsencrypt.old
  tar -zxvf "/backups/letsencrypt/${_NEWEST_BACKUP_FILENAME}" -C /
}


##################################################################################
# LetsEncrypt container functions
##################################################################################

function save_letsencrypt_folder (){

  echo "save_letsecrypt_folder: $1" 
  check_required_s3cmd_vars
  if [ $? = 1 ]; then exit 1 ;fi
  write_s3cmd_config
  save_letsencrypt_folder_to_s3 $1

}

function restore_letsencrypt_folder () {

  local _BACKUP_FILENAME_PREFIX=$1
  #Make sure all required env vars have been provided or die
  check_required_cloudflare_vars
  if [ $? = 1 ]
    then
      echo "Exiting because of errors.."
    exit 1
  fi

  check_required_s3cmd_vars
  if [ $? = 1 ]; then exit 1 ;fi

  write_s3cmd_config
  #save_letsencrypt_folder_to_s3
  restore_letsencrypt_folder_from_s3 $_BACKUP_FILENAME_PREFIX

}

function request_ssl_for_domain  (){
  local _DOMAIN=$1

  #Make sure all required env vars have been provided or die
  check_required_cloudflare_vars
  if [ $? = 1 ]
    then
      echo "Exiting because of errors.."
    exit 1
  fi

  #Write the config file.
  #We just write it out all the time.
  write_cloudflare_ini

  #Now get the cert
  get_cert_for_domain  $_DOMAIN

}



