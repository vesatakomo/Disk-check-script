#!/bin/bash

REPORT="=== NEST Disk health report ===

"

# -----------------------
# 1️⃣ SAS disks (HP Smart Array, cciss,N)
# -----------------------

# Define SAS logical drives mapping: /dev/sdX -> cciss,N -> Bay
# Adjust this according to your OMV setup
declare -A SAS_MAP=( 
    ["/dev/sda"]="0:1" 
    ["/dev/sdb"]="1:2"
    ["/dev/sdc"]="2:3"
    ["/dev/sdd"]="3:4"
    ["/dev/sde"]="4:5"
)

for dev in "${!SAS_MAP[@]}"; do
    IFS=":" read -r cciss_index bay <<< "${SAS_MAP[$dev]}"

    SMART_OUT=$(smartctl -a -d cciss,$cciss_index $dev 2>/dev/null ||true)
    if ! echo "$SMART_OUT" | grep -q "SMART Health Status"; then
        continue
    fi

    read_corrected=$(echo "$SMART_OUT" | awk '/^read:/ {print $5}')
    read_uncorrected=$(echo "$SMART_OUT" | awk '/^read:/ {print $8}')
    write_corrected=$(echo "$SMART_OUT" | awk '/^write:/ {print $5}')
    write_uncorrected=$(echo "$SMART_OUT" | awk '/^write:/ {print $8}')
    non_medium=$(echo "$SMART_OUT" | awk -F: '/Non-medium error count/ {print $2}' | tr -d ' ')
    grown_defects=$(echo "$SMART_OUT" | awk -F: '/Elements in grown defect list/ {print $2}' | tr -d ' ')
    health=$(echo "$SMART_OUT" | awk -F: '/SMART Health Status/ {print $2}' | tr -d ' ')

    prefix=""
    if [[ "$read_corrected" -gt 0 || "$read_uncorrected" -gt 0 || "$write_corrected" -gt 0 || "$write_uncorrected" -gt 0 || "$grown_defects" -gt 0 || "$non_medium" -gt 0 || "$health" != "OK" ]]; then
        prefix="⚠️ "
    fi

    REPORT+="_________________________
${prefix}Bay $bay SAS
SMART health: $health
Read corrected errors: $read_corrected
Read uncorrected errors: $read_uncorrected
Write corrected errors: $write_corrected
Write uncorrected errors: $write_uncorrected
Grown defect list: $grown_defects
Non-medium error count: $non_medium

"
done

# -----------------------
# 2️⃣ SATA disks
# -----------------------

for disk in $(smartctl --scan | awk '{print $1}'); do
    # Skip SAS drives already handled
    [[ -n "${SAS_MAP[$disk]}" ]] && continue

    SMART_OUT=$(smartctl -a $disk)

    model=$(echo "$SMART_OUT" | awk -F: '/Device Model|Product/ {print $2; exit}' | xargs)
    health=$(echo "$SMART_OUT" | awk -F: '/SMART overall-health|SMART Health Status/ {print $2}' | xargs)
    realloc=$(echo "$SMART_OUT" | awk '/Reallocated_Sector_Ct/ {print $10}')
    pending=$(echo "$SMART_OUT" | awk '/Current_Pending_Sector/ {print $10}')
    offline=$(echo "$SMART_OUT" | awk '/Offline_Uncorrectable/ {print $10}')

    prefix=""
    if [[ "$realloc" -gt 0 || "$pending" -gt 0 || "$offline" -gt 0 || "$health" != "PASSED" && "$health" != "OK" ]]; then
        prefix="⚠️ "
    fi

    REPORT+="__________________________
${prefix}$disk $model
SMART health: $health
Reallocated sectors: $realloc
Pending sectors: $pending
Offline uncorrectable: $offline

"
done

# -----------------------
# 3️⃣ Send to Telegram via Apprise
# -----------------------

curl -X POST \
     -F "body=$REPORT" \
     -F "tags=all" \
     http://192.168.1.5:18000/notify/apprise
