
build-8-jre:
	docker build -t meisterplan/openjdk-springboot:$(TAG) -f 8-jre.Dockerfile .