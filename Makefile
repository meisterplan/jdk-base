build:
	echo "These images are usually built by DockerHub, run a specific target, if you must"

build-8:
	docker build -t meisterplan/jdk-base:8 -f 8.Dockerfile .

build-11:
	docker build -t meisterplan/jdk-base:11 -f 11.Dockerfile .

build-11-alpine:
	docker build -t meisterplan/jdk-base:11-alpine -f 11-alpine.Dockerfile .

build-11-openjdk:
	docker build -t meisterplan/jdk-base:11-openjdk -f 11-openjdk.Dockerfile .