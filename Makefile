build-8-jdk:
	docker build -t meisterplan/openjdk-springboot:8-jdk -f 8-jdk.Dockerfile .

build-10-jdk:
	docker build -t meisterplan/openjdk-springboot:10-jdk -f 10-jdk.Dockerfile .

build-11-jdk:
	docker build -t meisterplan/openjdk-springboot:11-jdk -f 11-jdk.Dockerfile .
