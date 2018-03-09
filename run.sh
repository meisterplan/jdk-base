#!/bin/bash

CGROUPS_MEM_LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)

JAVA_XMX=$((($CGROUPS_MEM_LIMIT-$JAVA_NON_HEAP_MEMORY_BYTES)/1024/1024))m

OPTS="-Xmx$JAVA_XMX \
-XX:MaxMetaspaceSize=$JAVA_MAX_METASPACE_SIZE \
-Xss$JAVA_STACK_SIZE \
-XX:ReservedCodeCacheSize=$JAVA_RESERVED_CODE_CACHE_SIZE \
-XX:CompressedClassSpaceSize=$JAVA_COMPRESSED_CLASS_SPACE_SIZE \
-XX:MaxDirectMemorySize=$JAVA_MAX_DIRECT_MEMORY_SIZE \
$JMX_CONFIG"

echo "Java launch options: $OPTS"

exec java $OPTS -jar $SERVICE_JAR
