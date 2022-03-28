REGISTRY_URL=jnvilo
PROJECT=library
IMAGE_NAME=letsencrypt
TAG=0.0.1

.PHONY: build  all build_image pull tag clean 

all:  build tag push

build_image:
	docker build -t "${IMAGE_NAME}:latest" -f "Dockerfile" .

pull:   
	docker  pull ${REGISTRY_URL}/${PROJECT}/${IMAGE_NAME}:latest 

tag: build
	docker tag ${REGISTRY_URL}/${PROJECT}/${IMAGE_NAME}:${TAG} ${REGISTRY_URL}/${PROJECT}/${IMAGE_NAME}:latest


build: build_image 
	docker tag "${IMAGE_NAME}:latest"  ${REGISTRY_URL}/${PROJECT}/${IMAGE_NAME}:latest
	docker tag "${IMAGE_NAME}:latest"  ${REGISTRY_URL}/${PROJECT}/${IMAGE_NAME}:${TAG}
 
push:  build
	docker push ${REGISTRY_URL}/${PROJECT}/${IMAGE_NAME}:latest
	docker push ${REGISTRY_URL}/${PROJECT}/${IMAGE_NAME}:${TAG}

shell: build 
	docker run \
		-e CLOUDFLARE_DNS_TOKEN \
		-e CLOUDFLARE_DNS_EMAIL \
		-e S3CMD_ACCESS_KEY \
      		-e S3CMD_SECRET_KEY \
      		-e S3CMD_HOST_BASE \
		-v /home/jasonvi/PycharmProjects/cicd/abakus-docker-lab/var/letsencrypt:/etc/letsencrypt \
		-v /home/jasonvi/PycharmProjects/cicd/abakus-docker-lab/var/backups/letsencrypt:/backups/letsencrypt \
		--rm -it ${IMAGE_NAME}:latest /bin/bash 

clean:
	sudo rm -rf var
