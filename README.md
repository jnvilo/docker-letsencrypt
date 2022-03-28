## Image info.

The image is built on rockylinux:latest and has the required certbot packages and also letsencrypt modules. 
## Usage with cloudflare DNS authentication
	
### Required Tokens and Secrets 

#### Cloudflare: 
  * CLOUDFLARE_DNS_TOKEN - The API token from account cloud-admin@optiscangruop.com in cloudflare.com
  * CLOUDFLARE_DNS_EMAIL - cloud-admin@optiscangroup.com (or your own sub account)

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
