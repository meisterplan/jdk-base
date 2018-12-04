# Spring Boot Docker Images

These images provide a preconfigured base image for Docker. It allows simplified deploys in orchestration systems like [Kubernetes](https://kubernetes.io/).

## Available images

We have currently pre-built images for openjdk in version 8, 10 and 11 based on AdoptOpenJDK.

* [`meisterplan/openjdk-springboot:8-jdk`](https://hub.docker.com/r/meisterplan/openjdk-springboot/tags/)
* [`meisterplan/openjdk-springboot:10-jdk`](https://hub.docker.com/r/meisterplan/openjdk-springboot/tags/)
* [`meisterplan/openjdk-springboot:11-jdk`](https://hub.docker.com/r/meisterplan/openjdk-springboot/tags/)

## Supported features

This image has some advantages to a simple `(adopt)openjdk` as a base image.

### Preconfigured launch

The Docker image will automatically launch a spring boot application which can either be deployed as a fat JAR or an uncompressed folder with class files (aka exploded JAR).
The starting mechanism will be automatically configured depending on whether `/service.jar` or a folder named `/service` is present.

### Enabled JMX port

Enabling JMX will allow you to connect to the application using tools like [VisualVM](https://visualvm.github.io/).

The docker image will automatically enable JMX under port 5005. Ensure that this port is **never** exposed to the public.

To disable JMX support set the environment variable `JMX_CONFIG` to an empty value.

### Port defaults

The started spring boot application will have pre-configured the ports for server and management on `8080` and `8081` respectively.

### Off heap defaults

Java uses some memory off the heap. Heap limits can be configured with `-Xmx`. Using this limit in an Docker environment may cause dificulties.

Therefore this image has the ability to automatically configure the heap limit according to the configured cgroups limit of the docker container.

Because each Java application has a different off heap memory footprint the limit is configurable using the environment variable `JAVA_NON_HEAP_MEMORY_BYTES`. Configure this variable to a size which matches the required off heap memory used by your application.

An example where too few off heap memory is granted is when Kubernetes kills your application with the reason `OOMKilled`. Then you shoud increase the `JAVA_NON_HEAP_MEMORY_BYTES`.

## Using the image

If you have a built spring boot application you can use a simple Dockerfile like in the following example to build your docker image.

```Dockerfile
FROM meisterplan/openjdk-springboot:8-jre
# 400mb off heap memory
ENV JAVA_NON_HEAP_MEMORY_BYTES 400000000
COPY "build/libs/myservice-1.0.0-SNAPSHOT.jar" "/service.jar"
```

This is enough to build & run you application.
