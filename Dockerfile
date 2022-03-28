FROM harbor.abakuscloud.com/library/python39:latest

RUN yum -y install epel-release
RUN yum -y install certbot python3-certbot-dns-cloudflare s3cmd

RUN  mkdir -p /opt/certbot && mkdir -p /backups/letsencrypt
COPY certbot  /opt/certbot
RUN chmod 755 /opt/certbot/*


