#!/bin/sh -e

varnishkafka -n varnishd | \
    logger --size=32768 --stderr --no-act --tag varnishkafka 2>&1 | \
    while true; do
        socat -d -d - TCP4:10.42.24.10:514,connect-timeout=5,forever || true
        sleep 5
    done
