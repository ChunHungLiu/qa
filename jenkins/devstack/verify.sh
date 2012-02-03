#!/bin/bash
set -eux

let i=1
while [ $i -lt 30 ]
do
    ((i++))
    verif=$(cat /opt/stack/run.sh.log | grep -o --only-matching "stack.sh completed in [0-9]* seconds" || true)
    if [ -z "$verif" ]
    then
        sleep 60
    else
        echo "verify done with success"
        exit 0
    fi
done
echo "verify failed"
exit 1