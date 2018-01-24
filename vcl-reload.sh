#!/bin/sh -e

INSTANCE='varnishd'
NAME="vcl-$(date +%F_%H%M%S)"

SOURCE="/usr/src/varnish/"
DEST="/etc/varnish/"

rsync -av --delete "$SOURCE" "$DEST"

varnishadm -n "$INSTANCE" ping || exit 0

for vcl in $(varnishadm -n "$INSTANCE" vcl.list | awk '!/^active/ { print $4 }'); do
    echo "cleaning vcl file '${vcl}'"
    varnishadm -n "$INSTANCE" vcl.discard "${vcl}"
done

varnishadm -n "$INSTANCE" vcl.load "${NAME}" "${DEST}/vcl/custom.vcl"
varnishadm -n "$INSTANCE" vcl.use "${NAME}"

varnishadm -n "$INSTANCE" < "${DEST}/settings.cli"
