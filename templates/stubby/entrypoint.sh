#!/bin/bash

if [ "$1" = 'stubby' ]; then
    shift
    # Configure named execution
    set -- "${STUBBY_INSTALLATION_DIR}/bin/stubby" -C "${STUBBY_CONFIGURATION}" "$@"
fi

exec "$@"
