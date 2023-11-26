#!/bin/bash

SED=${SED:-"sed"}

if [ "$1" == "-h" ] || ([ "$1" != "prod" ] && [ "$1" != "mock" ] && [ $# -gt 0 ] ) || [ $# -gt 1 ]; then
  echo "Usage: `basename $0` <prod|mock>"
  exit 0
fi

if [ "$1" == "prod" ] || [ $# -eq 0 ]; then
    find src -type f -name '*.sol' | $SED 's/src\///' | xargs -I {} gpp \
            -U "" "" "(" "," ")" "(" ")" "//:#" "\\" \
            -M "//:#" "\n" " " " " "\n" "(" ")" \
            -I "src" \
            src/{} -o ready_src/{}
else
    find src -type f -name '*.sol' | $SED 's/src\///' | xargs -I {} gpp \
            -U "" "" "(" "," ")" "(" ")" "//:#" "\\" \
            -M "//:#" "\n" " " " " "\n" "(" ")" \
            -I "src" \
            src/{} -o ready_src/{} \
            -Dtest
fi
