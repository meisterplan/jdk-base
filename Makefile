build:
	echo "These images are usually built by DockerHub, run a specific target, if you must"

build-11-alpine:
	docker build -t meisterplan/jdk-base:11-alpine -f 11-alpine.Dockerfile .

build-corretto-11-alpine:
	docker build -t meisterplan/jdk-base:corretto-11-alpine -f corretto-11-alpine.Dockerfile .
