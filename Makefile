build:
	echo "These images are usually built by DockerHub, run a specific target, if you must"

build-11-alpine:
	docker build -t meisterplan/jdk-base:11-alpine -f 11-alpine.Dockerfile .

build-11-ubuntu:
	docker build -t meisterplan/jdk-base:11-ubuntu -f 11-ubuntu.Dockerfile .
