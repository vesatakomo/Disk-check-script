#!/bin/bash

# Check physical drive status
PHYSICAL=$(ssacli controller slot=0 physicaldrive all show status | grep -v "OK")

# Check logical drive status
LOGICAL=$(ssacli controller slot=0 logicaldrive all show status | grep -v "OK")

if [[ -n "$PHYSICAL" || -n "$LOGICAL" ]]; then
    REPORT="A RAID issue has been detected on your HP Smart Array controller.

"

    if [[ -n "$PHYSICAL" ]]; then
        REPORT+="❌ Physical Drive Issues:
$PHYSICAL

"
    fi

    if [[ -n "$LOGICAL" ]]; then
        REPORT+="❌ Logical Drive Issues:
$LOGICAL

"
    fi

    # Send to Apprise via curl
    curl -X POST \
         -F "body=$REPORT" \
         -F "tags=all" \
         http://192.168.1.5:18000/notify/apprise
fi
