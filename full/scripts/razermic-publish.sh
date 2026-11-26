#!/bin/bash
# One-shot root publisher for RazerSSTMicrophone on this machine.
# Waits for a normal console login and >=70 s uptime, then arms publication once.
export PATH=/usr/sbin:/usr/bin:/bin
PUB=/usr/local/sbin/razermic-publish-helper
SVC=RazerSSTMicrophone
for i in $(seq 1 180); do
    BOOT=$(sysctl -n kern.boottime | sed -E 's/.*sec = ([0-9]+).*/\1/')
    NOW=$(date +%s)
    UP=$((NOW - BOOT))
    USER_NAME=$(stat -f %Su /dev/console 2>/dev/null)
    if [ "$UP" -ge 70 ] && [ -n "$USER_NAME" ] && [ "$USER_NAME" != "root" ]; then
        break
    fi
    sleep 2
done
if ioreg -r -c "$SVC" -l -w0 2>/dev/null | grep -q '"PublishesAudioInput" = Yes'; then
    echo "$(date) already published" >> /var/log/razermic-publish.log
    exit 0
fi
ioreg -r -c "$SVC" -l -w0 2>/dev/null | grep -q '"Version" = "0.3.3-DMIC16K-RPL"' || exit 1
"$PUB" >/dev/null 2>&1
RC=$?
sleep 2
if ioreg -r -c "$SVC" -l -w0 2>/dev/null | grep -q '"PublishesAudioInput" = Yes'; then
    echo "$(date) published rc=$RC" >> /var/log/razermic-publish.log
    exit 0
fi
echo "$(date) publish failed rc=$RC" >> /var/log/razermic-publish.log
exit 1
