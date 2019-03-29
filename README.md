# jdk-base

These images provide a preconfigured base image to run JVM application with Docker. They're geared towards [Spring Boot](https://spring.io/projects/spring-boot) but generally allow any JVM application to run. It can be used to simplify deploys in orchestration systems like [Kubernetes](https://kubernetes.io/).

This repository supersedes the earlier [docker-openjdk-springboot Image](https://github.com/meisterplan/docker-openjdk-springboot).

## Available images

We have currently pre-built images for AdoptOpenJDK in version 8 and 11 as well as OpenJDK 11.

| Image                                                                                    | JDK version | JDK variant  | Base OS            |
| ---------------------------------------------------------------------------------------- | ----------- | ------------ | ------------------ |
| [`meisterplan/jdk-base:8`](https://hub.docker.com/r/meisterplan/jdk-base/tags/)          | 1.8         | AdoptOpenJDK | Ubuntu 18.04       |
| [`meisterplan/jdk-base:11`](https://hub.docker.com/r/meisterplan/jdk-base/tags/)         | 11          | AdoptOpenJDK | Ubuntu 18.04       |
| [`meisterplan/jdk-base:11-alpine`](https://hub.docker.com/r/meisterplan/jdk-base/tags/)  | 11          | AdoptOpenJDK | Alpine 3.9         |
| [`meisterplan/jdk-base:11-openjdk`](https://hub.docker.com/r/meisterplan/jdk-base/tags/) | 11          | OpenJDK      | Debian 9 (Stretch) |

## Using the image

If you have a built spring boot application you can use a simple Dockerfile like in the following example to build your docker image.

```Dockerfile
FROM meisterplan/jdk-base:11-alpine
COPY "build/libs/myservice-1.0.0-SNAPSHOT.jar" "/service.jar"
```

This is enough to build & run your application.

## Advantages to a plain JDK image

### Preconfigured launch

The Docker image will automatically launch a JAR application (like produced by Spring Boot) which can either be deployed as a fat JAR or an uncompressed folder with class files (aka exploded JAR).
The starting mechanism will be automatically configured depending on whether `/service.jar` (configurable via `SERVICE_JAR`) or a folder named `/service` (configurable via `SERVICE_FOLDER`) is present.

You can pass in your own JVM options via the env `JVM_OPTS`.

### Enabled JMX port

Enabling JMX will allow you to connect to the application using tools like [VisualVM](https://visualvm.github.io/).

The docker image will automatically enable JMX under port 5005. Ensure that this port is **never** exposed to the public.

To disable JMX support set the environment variable `JMX_CONFIG` to an empty value ("").

### Port defaults

The container will pre-configure Spring Boot variables for `SERVER_PORT` and `MANAGEMENT_SERVER_PORT` on `8080` and `8081` respectively (which can easily be overridden).

### Readiness and Liveness checks

The container ships with a [k8s-health-check](https://github.com/meisterplan/k8s-health-check) binary. This allows to disable those checks when you need to debug the container in production.
Per default they access the Spring Boot paths "localhost:8081/actuator" for liveness and "localhost:8081/actuator/health" for readiness checks. More details on how to use this mechanism with Kubernetes can be found in the k8s-health-check docs.

### Memory settings

The JVM has complex memory requirements which split into native, heap, metaspace memory, etc. Following the recommendations from [CloudFoundry's Java Memory Calculator](https://github.com/cloudfoundry/java-buildpack-memory-calculator) we have made it simple to adjust the JVM memory.

The container can automatically compute typical required JVM memory limits from a few data points and allows overriding them individually. Note that:

- If no cgroups memory limit is detected, no limits can be inferred and thus none are set
- The container assumes all non-heap memory to be a fixed size and rescales the available heap memory based on the available memory (from the cgroups limit)
- `-XX:+ExitOnOutOfMemoryError` is passed to the JVM so that containers which have OOM failed can be safely restarted by the underlying container orchestrator

- If the JVM is still capable to log an `OutOfMemory` exception, it has probably run out of heap or metaspace.
- If your orchestrator gives you `OOMKilled` with exit code 137 this usually means that the JVM has run out of native space.

#### Automatic computation

If your application is already running somewhere and you can estimate your required heap memory (in MB), number of running threads and number of classes loaded, you can compute your total container max memory (in MB) by:

`Total Container Memory = ( 264 + Heap + #Threads + 0.00553131103 * #Classes ) / 0.85`

and then set:
```
ENV JVM_MEM_THREAD_COUNT "#Threads"
ENV JVM_MEM_LOADED_CLASSES_COUNT "#Classes"
```

The container then works this out as follows:

- The total memory of the container is multiplied by `1 - (JVM_MEM_OVERHEAD_PERCENT / 100)` to leave space for native memory headroom
- Direct Memory is set to 10M
- Reserved Code Cache is set to 240M
- Metaspace is set to the heuristic (5,800 * #Classes + 14,000,000) bytes
- Compressed Class Space is not set since it is already limited by metaspace
- Stack size is set to 1M (which counts per Thread)
- The remaining memory is used for the heap (`Xmx`)

If you have no idea at all, the provided defaults `JVM_MEM_THREAD_COUNT = 45` and `JVM_MEM_LOADED_CLASSES_COUNT = 12,000` should be able to start a basic Spring Boot application with 512M total memory.

#### Manual overrides

- `JVM_MEM_OVERHEAD_PERCENT` *default 15*: Percent between 1 and 99, how much space (percentage) should be reserved for native memory
- `JVM_MEM_DIRECT_MEMORY` *default 10*: How many MB should be used for `-XX:MaxDirectMemorySize`
- `JVM_MEM_RESERVED_CODE_CACHE` *default 240*: How many MB should be used for `-XX:ReservedCodeCacheSize`
- `JVM_MEM_STACK_SIZE` *default 1024*: How many KB should be used for `-Xss`
- `JVM_MEM_METASPACE_SIZE` *default computed by JVM_LOADED_CLASSES_COUNT*: How much should be used for `-XX:MaxMetaspaceSize`
- `JVM_MEM_HEAP_SIZE` *default computed by all other input parameters*: How much should be used for `-Xmx`