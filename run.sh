#!/bin/sh

fp_calc() {
    awk "BEGIN{print $*}";
}

fp_calc_to_int() {
    fp_calc "$*" | xargs printf %.0f
}

CGROUPS_MEM_LIMIT_BYTES=$(cat /sys/fs/cgroup/memory.max /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null)

if [ "$CGROUPS_MEM_LIMIT_BYTES" = "9223372036854771712" ] || [ "X${CGROUPS_MEM_LIMIT_BYTES}X" = "XX" ]; then
    echo "There is no cgroups memory limit in place, falling back to default behavior (not setting any limit)."
    CALCULATED_OPTS=""
else
    CGROUPS_MEM_LIMIT_MIB=$(( $CGROUPS_MEM_LIMIT_BYTES / 1048576 ))
    echo "Container is started with $CGROUPS_MEM_LIMIT_MIB MiB total memory"

    if [ -z "$JVM_MEM_METASPACE_SIZE_MIB" ]; then
        JVM_MEM_METASPACE_SIZE_MIB=$(( 1 + ($JVM_MEM_LOADED_CLASSES_COUNT * 5800 + 14000000) / 1048576 ))
        echo "MaxMetaspaceSize computed to be $JVM_MEM_METASPACE_SIZE_MIB MiB"
    fi

    if [ -z "$JVM_MEM_HEAP_SIZE_MIB" ]; then
        PURE_JVM_MEMORY_MIB=$( fp_calc_to_int "$CGROUPS_MEM_LIMIT_MIB * (1 - ($JVM_MEM_OVERHEAD_PERCENT / 100))" )
        TOTAL_STACK_SIZE_MIB=$(( $JVM_MEM_STACK_SIZE_KIB * JVM_MEM_THREAD_COUNT / 1024 ))
        JVM_MEM_HEAP_SIZE_MIB=$(( $PURE_JVM_MEMORY_MIB - $JVM_MEM_DIRECT_MEMORY_MIB - $JVM_MEM_RESERVED_CODE_CACHE_MIB - $JVM_MEM_METASPACE_SIZE_MIB - $TOTAL_STACK_SIZE_MIB ))
        echo "Available Heap Size computed to be $JVM_MEM_HEAP_SIZE_MIB MiB (from pure JVM memory = $PURE_JVM_MEMORY_MIB MiB and total stack size = $TOTAL_STACK_SIZE_MIB MiB)"
    fi

    if [ "$JVM_MEM_HEAP_SIZE_MIB" -lt "32" ]; then
        echo "PANIC: We're trying to start with less than 32 MiB heap, defaulting back to that. Check your input parameters."
        JVM_MEM_HEAP_SIZE_MIB=32
    fi

    CALCULATED_OPTS="-Xmx${JVM_MEM_HEAP_SIZE_MIB}m \
-XX:MaxMetaspaceSize=${JVM_MEM_METASPACE_SIZE_MIB}m \
-Xss${JVM_MEM_STACK_SIZE_KIB}k \
-XX:ReservedCodeCacheSize=${JVM_MEM_RESERVED_CODE_CACHE_MIB}m \
-XX:MaxDirectMemorySize=${JVM_MEM_DIRECT_MEMORY_MIB}m"
fi
OPTS="$CALCULATED_OPTS \
-XX:+ExitOnOutOfMemoryError \
$JMX_CONFIG \
$JVM_OPTS"

echo "Complete JVM launch options: $OPTS"

if [ -f "$SERVICE_JAR" ]; then
    exec $SU_BINARY jdkservice sh -c "exec java $OPTS -jar $SERVICE_JAR"
elif [ -d "$SERVICE_FOLDER" ]; then
    exec $SU_BINARY jdkservice sh -c "exec java $OPTS -cp $SERVICE_FOLDER org.springframework.boot.loader.JarLauncher"
else
    echo "ERROR: Cannot start: Must supply either $SERVICE_JAR or $SERVICE_FOLDER"
fi
