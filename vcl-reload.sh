#!/bin/sh -xe

INSTANCE='varnishd'
NAME="vcl-$(date +%F_%H%M%S)"

SOURCE="/usr/src/varnish/"
DEST="/etc/varnish/"

rsync -av --delete "$SOURCE" "$DEST"

varnishadm -n "$INSTANCE" ping || exit 0

for vcl in $(varnishadm -n "$INSTANCE" vcl.list -j | jq -r '.[] | objects | select(.status != "active" and .temperature != "cold") | .name'); do
    echo "cleaning vcl file '${vcl}'"
    varnishadm -n "$INSTANCE" vcl.discard "${vcl}"
done

varnishadm -n "$INSTANCE" vcl.load "${NAME}" "${DEST}/vcl/custom.vcl"
varnishadm -n "$INSTANCE" vcl.use "${NAME}"

varnishadm -n "$INSTANCE" < "${DEST}/settings.cli"
