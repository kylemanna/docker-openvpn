#!/bin/bash

set -x

cd "$(dirname "$(readlink -f "$0")")/tests"
let cnt=0

for i in *.sh; do
    cnt=$(($cnt + 1))
    echo -e "\n>> Running test #$cnt \"$i\"\n"
    ./${i}
    retval=$?
    if [ $retval != 0 ]; then
        echo ">> FAILED test #$cnt \"$i\", exit code $retval"
        exit $retval
    fi
done

echo ">> All $cnt tests PASSED"
