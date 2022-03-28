## Image info.

The image is built on rockylinux:latest and has the required certbot packages and also letsencrypt modules. However the main use case for this is to be able to request certificates for <FOO>.abakuscloud.com SSL certificates easily. 
## Usage:

### Required Tokens and Secrets 

#### Cloudflare: 
  * CLOUDFLARE_DNS_TOKEN - The API token from account cloud-admin@optiscangruop.com in cloudflare.com
  * CLOUDFLARE_DNS_EMAIL - cloud-admin@optiscangroup.com (or your own sub account)

#### S3CMD for the AbakusCloud Object Storage Access
 * S3CMD_ACCESS_KEY  - Access key to our AbakusCloud Object Storage
 * S3CMD_SECRET_KEY  - Secret key to our Abakuscloud object storage. 

If you do not have these keys, please ask <jason.viloria@optiscangroup.com>

### To get a certificate:

```commandline
docker run \
	-e CLOUDFLARE_DNS_TOKEN \
	-e CLOUDFLARE_DNS_EMAIL \
	-v `pwd`/letsencrypt:/etc/letsencrypt
	--rm -it ${IMAGE_NAME}:latest /opt/certbot/issue_cert.sh  <FOO>.abaksucloud.com 
```
Running the above command will issue a certificate on the letsencrypt directory is made accessible to you through the path `pdw`/letsencrypt that was provided in the command above. 



### To access the shell and work directly inside the container. 

```
docker run \
	-e CLOUDFLARE_DNS_TOKEN \
	-e CLOUDFLARE_DNS_EMAIL \
	-v `pwd`/letsencrypt:/etc/letsencrypt
	--rm -it ${IMAGE_NAME}:latest /bin/bash 
```

## Integrating within other containers.

The use case of this image is to provide and manage SSL certificates for other services. For example if we have an nginx service in another container, then we can use this container to provide the SSL certificate in a shared volume. 

The docker-compose file shown below gives an idea of how to use this. When user runs docker-compose up, the container will issue the certficates. 
If the certificates already exists then it will just try to renew them if required. 

The example below shows how an nginx container may then get access to the certificates. 

```
Version: '3.6'
services:
  letsencrypt: 
    image: harbor.abakuscloud.com/library/letsencrypt   latest
    container_name: letsencrypt
    command: "/bin/bash /opt/certbot/issue_certs.sh  myserver.abakuscloud.com"  
    hostname: letsencrypt  
    volumes:
      - "./var/letsencrypt:/etc/letsencrypt"
	environment:
	  - CLOUDFLARE_DNS_TOKEN 
	  - CLOUDFLARE_DNS_EMAIL 
  nginx:
    image: nginx:latest
	volumes:
	  - "./var/letsencrypt:/etc/letsencrypt"
```

### Things to note with the above example

The whole letsencrypt directory is saved in the local volume path ./var/letsencrypt. You will need to make
sure that if you redeploy this container elsewhere , then you must copy the ./var/letsencrypt folder to the 
new location. 

## Saving and Restoring the letsencrypt directory. 

The image also provides two scripts to save the /etc/letsencrypt folder to our abakuscloud hosting. 

In order to be able to do this, you will need to have the values for
 * S3CMD_ACCESS_KEY 
 * S3CMD_SECRET_KEY 
 
### Example Workflow:

Using the same dockerfile example: 

```
Version: '3.6'
services:
  letsencrypt: 
    image: harbor.abakuscloud.com/library/letsencrypt   latest
    container_name: letsencrypt
    command: "/bin/bash /opt/certbot/issue_certs.sh  myserver.abakuscloud.com"  
    hostname: letsencrypt  
    volumes:
      - "./var/letsencrypt:/etc/letsencrypt"
	environment:
	  - CLOUDFLARE_DNS_TOKEN 
	  - CLOUDFLARE_DNS_EMAIL 
  nginx:
    image: nginx:latest
	volumes:
	  - "./var/letsencrypt:/etc/letsencrypt"
```

#### Save to the cloud

First make sure you also define some environmental variables. 
```commandline
export IMAGE_NAME="harbor.abakuscloud.com/library/letsencrypt:latest"
export  BACKUP_FILE_PREFIX="my-letsencrypt-certificates"   

docker run \
                -e CLOUDFLARE_DNS_TOKEN \
                -e CLOUDFLARE_DNS_EMAIL \
                -e S3CMD_ACCESS_KEY \
                -e S3CMD_SECRET_KEY \
                -e S3CMD_HOST_BASE \
                -v "./var/letsencrypt:/etc/letsencrypt \
                --rm -it ${IMAGE_NAME}:latest /opt/certbot/backup_certs $BACKUP_FILE_PREFIX
```

#### Restore from cloud

The image contains a script /opt/certbot/restore_certs.sh $BACKUP_FILE_PREFIX, which will search 
for the latest backup that starts with the value of $BACKUP_FILE_PREFIX and restore it to the 
containers /etc/letsencrypt folder. This can then be shared and used by other containers in your
docker-compose file as is needed, or accessed by you in the mounted ./var/letsencrypt folder as 
is passed in the example.


```commandline
export IMAGE_NAME="harbor.abakuscloud.com/library/letsencrypt:latest"
export BACKUP_FILE_PREFIX="my-letsencrypt-certificates"   

docker run \
                -e CLOUDFLARE_DNS_TOKEN \
                -e CLOUDFLARE_DNS_EMAIL \
                -e S3CMD_ACCESS_KEY \
                -e S3CMD_SECRET_KEY \
                -e S3CMD_HOST_BASE \
                -v "./var/letsencrypt:/etc/letsencrypt \
                --rm -it ${IMAGE_NAME}:latest /opt/certbot/restore_certs.sh $BACKUP_FILE_PREFIX
```







