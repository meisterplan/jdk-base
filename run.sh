#!/bin/sh

fp_calc() {
    awk "BEGIN{print $*}";
}

fp_calc_to_int() {
    fp_calc "$*" | xargs printf %.0f
}

CGROUPS_MEM_LIMIT_BYTES=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)

if [ "$CGROUPS_MEM_LIMIT_BYTES" = "9223372036854771712" ] || [ "X${CGROUPS_MEM_LIMIT_BYTES}X" = "XX" ]; then
    echo "There is no cgroups memory limit in place, falling back to default behavior (not setting any limit)."
    JAVA_XMX=""

    CALCULATED_OPTS=""
else
    CGROUPS_MEM_LIMIT_MB=$(( $CGROUPS_MEM_LIMIT_BYTES / 1048576 ))
    echo "Container is started with $CGROUPS_MEM_LIMIT_MB MiB total memory"

    if [ -z "$JVM_MEM_METASPACE_SIZE" ]; then
        JVM_MEM_METASPACE_SIZE=$(( 1 + ($JVM_MEM_LOADED_CLASSES_COUNT * 5800 + 14000000) / 1048576 ))
        echo "MaxMetaspaceSize computed to be $JVM_MEM_METASPACE_SIZE MiB"
    fi

    if [ -z "$JVM_MEM_HEAP_SIZE" ]; then
        PURE_JVM_MEMORY_MB=$( fp_calc_to_int "$CGROUPS_MEM_LIMIT_MB * (1 - ($JVM_MEM_OVERHEAD_PERCENT / 100))" )
        TOTAL_STACK_SIZE_MB=$(( $JVM_MEM_STACK_SIZE * JVM_MEM_THREAD_COUNT / 1024 ))
        JVM_MEM_HEAP_SIZE=$(( $PURE_JVM_MEMORY_MB - $JVM_MEM_DIRECT_MEMORY - $JVM_MEM_RESERVED_CODE_CACHE - $JVM_MEM_METASPACE_SIZE - $TOTAL_STACK_SIZE_MB ))
        echo "Available Heap Size computed to be $JVM_MEM_HEAP_SIZE"
    fi

    if [ "$JVM_MEM_HEAP_SIZE" -lt "32" ]; then
        echo "PANIC: We're trying to start with less than 32 MiB heap, defaulting back to that. Check your input parameters."
        JVM_MEM_HEAP_SIZE=32
    fi

    CALCULATED_OPTS="-Xmx${JVM_MEM_HEAP_SIZE}m \
-XX:MaxMetaspaceSize=${JVM_MEM_METASPACE_SIZE}m \
-Xss${JVM_MEM_STACK_SIZE}k \
-XX:ReservedCodeCacheSize=${JVM_MEM_RESERVED_CODE_CACHE}m \
-XX:MaxDirectMemorySize=${JVM_MEM_DIRECT_MEMORY}m"
fi
OPTS="$CALCULATED_OPTS
-XX:+ExitOnOutOfMemoryError \
$JMX_CONFIG \
$JVM_OPTS"

echo "Complete JVM launch options: $OPTS"

if [ -f "$SERVICE_JAR" ]; then
	exec java $OPTS -jar $SERVICE_JAR
elif [ -d "$SERVICE_FOLDER" ]; then
	exec java $OPTS -cp $SERVICE_FOLDER org.springframework.boot.loader.JarLauncher
else
	echo "ERROR: Cannot start: Must supply either $SERVICE_JAR or $SERVICE_FOLDER"
fi
