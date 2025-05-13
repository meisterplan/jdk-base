GITHUB_REF_NAME?=dev
BRANCH:=$(shell echo "$(GITHUB_REF_NAME)" | sed -e 's/[^a-zA-Z\-]//i')

setup-docker-buildx:
	docker run -d -p 5000:5000 --name temp-docker-registry registry:2 || docker start temp-docker-registry
	docker buildx create --name jdk-base-builds --driver-opt network=host || true
	docker buildx use jdk-base-builds

docker-buildx-setup-21:
	docker buildx use jdk-21-base-builds || docker buildx create --name jdk-21-base-builds --use

build-21-alpine-amd64:
	docker buildx build --platform=linux/amd64 --load --pull --build-arg image=eclipse-temurin:21-alpine -t meisterplan/jdk-base:21-alpine-amd64 -f alpine.Dockerfile .

publish-21-alpine-amd64: build-21-alpine-amd64
	docker push meisterplan/jdk-base:21-alpine-amd64


build-21-alpine-arm64: docker-buildx-setup-21
	docker buildx build --platform=linux/arm64 --load --pull --build-arg image=arm64v8/eclipse-temurin:21-alpine -t meisterplan/jdk-base:21-alpine-arm64 -f alpine.Dockerfile .

publish-21-alpine-arm64: build-21-alpine-arm64
	docker push meisterplan/jdk-base:21-alpine-arm64


build-21-alpine-manifest:
	docker manifest rm meisterplan/jdk-base:21-alpine || true
	$(eval AMD_64_DIGEST:=$(shell docker manifest inspect -v meisterplan/jdk-base:21-alpine-amd64 | jq -r '.Descriptor.digest'))
	$(eval ARM_64_DIGEST:=$(shell docker manifest inspect -v meisterplan/jdk-base:21-alpine-arm64 | jq -r '.Descriptor.digest'))
	docker manifest create meisterplan/jdk-base:21-alpine meisterplan/jdk-base@$(AMD_64_DIGEST) meisterplan/jdk-base@$(ARM_64_DIGEST)

publish-21-alpine-manifest: build-21-alpine-manifest
	docker manifest push meisterplan/jdk-base:21-alpine
