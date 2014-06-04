#!/bin/bash
#
# OpenVPN + Docker Wrapper Script
#

set -ex

abort() {
    echo "Error: $@"
    exit 1
}

if [ $# -lt 1 ]; then
    abort "No command specified"
fi

# Read arguments from command line
cmd=$1
shift

case "$cmd" in
    *)
        abort "Unknown cmd \"$cmd\""
        ;;
esac
