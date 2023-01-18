GITHUB_REF_NAME?=dev
BRANCH:=$(shell echo "$(GITHUB_REF_NAME)" | sed -e 's/[^a-zA-Z\-]//i')

setup-docker-buildx:
	docker run -d -p 5000:5000 --name temp-docker-registry registry:2 || docker start temp-docker-registry
	docker buildx create --name jdk-base-builds --driver-opt network=host || true
	docker buildx use jdk-base-builds


build-11-alpine-amd64:
	docker build --build-arg image=eclipse-temurin:11-alpine -t meisterplan/jdk-base:11-alpine-amd64 -f alpine.Dockerfile .

publish-11-alpine-amd64: build-11-alpine-amd64
	docker push meisterplan/jdk-base:11-alpine-amd64


build-11-alpine-arm64: setup-docker-buildx
	docker buildx build --platform=arm64 --push -t localhost:5000/docker-buildx-cache:openjdk11-alpine -f custom-base-images/11-alpine-arm.Dockerfile custom-base-images
	docker buildx build --platform=arm64 --build-arg image=localhost:5000/docker-buildx-cache:openjdk11-alpine -t meisterplan/jdk-base:11-alpine-arm64 -f alpine.Dockerfile .

publish-11-alpine-arm64: setup-docker-buildx
	docker buildx build --platform=arm64 --push -t localhost:5000/docker-buildx-cache:openjdk11-alpine -f custom-base-images/11-alpine-arm.Dockerfile custom-base-images
	docker buildx build --platform=arm64 --push --build-arg image=localhost:5000/docker-buildx-cache:openjdk11-alpine -t meisterplan/jdk-base:11-alpine-arm64 -f alpine.Dockerfile .


build-11-alpine-manifest:
	docker manifest rm meisterplan/jdk-base:11-alpine || true
	docker manifest create meisterplan/jdk-base:11-alpine meisterplan/jdk-base:11-alpine-amd64 meisterplan/jdk-base:11-alpine-arm64

publish-11-alpine-manifest: build-11-alpine-manifest
	docker manifest push meisterplan/jdk-base:11-alpine


build-17-alpine-amd64:
	docker build --build-arg image=eclipse-temurin:17-alpine -t meisterplan/jdk-base:17-alpine-amd64 -f alpine.Dockerfile .

publish-17-alpine-amd64: build-17-alpine-amd64
	docker push meisterplan/jdk-base:17-alpine-amd64


build-17-alpine-arm64: setup-docker-buildx
	docker buildx build --platform=arm64 --push -t localhost:5000/docker-buildx-cache:openjdk17-alpine -f custom-base-images/17-alpine-arm.Dockerfile custom-base-images
	docker buildx build --platform=arm64 --build-arg image=localhost:5000/docker-buildx-cache:openjdk17-alpine -t meisterplan/jdk-base:17-alpine-arm64 -f alpine.Dockerfile .

publish-17-alpine-arm64: setup-docker-buildx
	docker buildx build --platform=arm64 --push -t localhost:5000/docker-buildx-cache:openjdk17-alpine -f custom-base-images/17-alpine-arm.Dockerfile custom-base-images
	docker buildx build --platform=arm64 --push --build-arg image=localhost:5000/docker-buildx-cache:openjdk17-alpine -t meisterplan/jdk-base:17-alpine-arm64 -f alpine.Dockerfile .


build-17-alpine-manifest:
	docker manifest rm meisterplan/jdk-base:17-alpine || true
	docker manifest create meisterplan/jdk-base:17-alpine meisterplan/jdk-base:17-alpine-amd64 meisterplan/jdk-base:17-alpine-arm64

publish-17-alpine-manifest: build-17-alpine-manifest
	docker manifest push meisterplan/jdk-base:17-alpine
