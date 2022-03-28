docker run --rm \
	-v `pwd`/letsencrypt:/etc/letsencrypt \
	-e CLOUDFLARE_DNS_TOKEN \
	-e CLOUDFLARE_DNS_EMAIL \
	-e S3CMD_ACCESS_KEY \
	-e S3CMD_SECRET_KEY \
	-it letsencrypt /bin/bash 
