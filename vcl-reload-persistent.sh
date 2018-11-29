#!/bin/bash
CONFDIR="/etc/varnish"

: ${VCLFILE?"Variable must be defined for script to work."}
: ${INSTANCE?"Variable must be defined for script to work."}

if [ ! -d "$CONFDIR" ]; then
  echo "$CONFDIR must be a directory for script to work"
  exit 1
fi

cd "${CONFDIR}"

while inotifywait -qq -r -e modify,close_write,moved_from,delete,delete_self . ; do
  # make sure vcl is not compiled within the same second (wait for all inotify events to pass)
  sleep 1
  NAME="vcl-$(date +%F_%H%M%S)"

  # check if varnish is running correctly
  varnishadm -n "$INSTANCE" ping || {
    echo "Not reloading $CONFDIR/$VCLFILE since varnish is not running" > /dev/stderr
    continue
  }
  
  # cleanup old VCL
  for vcl in $(varnishadm -n "$INSTANCE" vcl.list | awk '!/^active/ { print $4 }'); do
      echo "cleaning vcl file '${vcl}'"
      varnishadm -n "$INSTANCE" vcl.discard "${vcl}"
  done
  
  varnishadm -n "$INSTANCE" vcl.load "${NAME}" "${CONFDIR}/${VCLFILE}"
  varnishadm -n "$INSTANCE" vcl.use "${NAME}"
done
