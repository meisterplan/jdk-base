ARG image
FROM ${image}

RUN apk add --no-cache su-exec curl

# OS defaults configuration
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

EXPOSE 8080 8081 5005

ENV SERVICE_JAR            /service.jar
ENV SERVICE_FOLDER         /service

ENV SERVER_PORT            8080
ENV MANAGEMENT_SERVER_PORT 8081

ENV JMX_CONFIG="-Dcom.sun.management.jmxremote=true \
    -Dcom.sun.management.jmxremote.ssl=false \
    -Dcom.sun.management.jmxremote.authenticate=false \
    -Dcom.sun.management.jmxremote.local.only=false \
    -Dcom.sun.management.jmxremote.port=5005 \
    -Dcom.sun.management.jmxremote.rmi.port=5005 \
    -Djava.rmi.server.hostname=127.0.0.1"

ENV JVM_OPTS ""

# Put these in for automated calculation, these are just minimal defaults
ENV JVM_MEM_THREAD_COUNT            45
ENV JVM_MEM_LOADED_CLASSES_COUNT    12000

# All of these can be overridden
ENV JVM_MEM_OVERHEAD_PERCENT        15
ENV JVM_MEM_DIRECT_MEMORY_MIB       10
ENV JVM_MEM_RESERVED_CODE_CACHE_MIB 240
ENV JVM_MEM_STACK_SIZE_KIB          1024
# computed by default
ENV JVM_MEM_METASPACE_SIZE_MIB      ""
# computed by default
ENV JVM_MEM_HEAP_SIZE_MIB           ""

ENV SU_BINARY su-exec
RUN curl -Lo /usr/bin/check https://github.com/meisterplan/k8s-health-check/releases/download/v0.1/check && chmod ugo+x /usr/bin/check

RUN addgroup -S jdkservice -g 202 && adduser -S -u 202 jdkservice jdkservice

ENV LIVENESS_CHECK "curl -m 1 -sf localhost:8081/actuator"
ENV READINESS_CHECK "curl -m 1 -sf localhost:8081/actuator/health"

ADD "run.sh" "/run.sh"

CMD ["./run.sh"]
