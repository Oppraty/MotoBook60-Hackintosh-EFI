#!/bin/bash
# Wait for FanMode sysctls, then select max cooling + DYTC performance.
# With hpmpl1=64 this is the best measured config: GB7 1153 / 6493.
export PATH=/usr/sbin:/usr/bin:/bin
for i in $(seq 1 90); do
    if sysctl -n debug.fanmode.mode >/dev/null 2>&1; then
        /usr/sbin/sysctl -w debug.fanmode.mode=4 >/dev/null 2>&1
        /usr/sbin/sysctl -w debug.fanmode.dytc=1224705 >/dev/null 2>&1
        exit 0
    fi
    sleep 1
done
exit 1
