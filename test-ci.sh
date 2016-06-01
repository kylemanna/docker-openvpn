#!/bin/bash

set -x

cd "$(dirname "$(readlink -f "$0")")/tests"

for i in *.sh; do
    echo -e "\n>> Running test $i\n"
    ./${i}
    retval=$?
    if [ $retval != 0 ]; then
        echo "Failed $i with exit code $retval"
        exit $retval
    fi
done
