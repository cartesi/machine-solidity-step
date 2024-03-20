#!/bin/bash

set -e

SED=${SED:-"sed"}

if [ "$1" == "-h" ] || ([ "$1" != "prod" ] && [ "$1" != "mock" ] && [ $# -gt 0 ] ) || [ $# -gt 1 ]; then
  echo "Usage: `basename $0` <prod|mock>"
  exit 0
fi

if [ "$1" == "prod" ] || [ $# -eq 0 ]; then
    gpp -U "" "" "(" "," ")" "(" ")" "//:#" "\\" \
        -M "//:#" "\n" " " " " "\n" "(" ")" \
        -I "templates" \
        templates/AccessLogs.sol.template -o src/AccessLogs.sol
else
    gpp -U "" "" "(" "," ")" "(" ")" "//:#" "\\" \
        -M "//:#" "\n" " " " " "\n" "(" ")" \
        -I "templates" \
        templates/AccessLogs.sol.template -o src/AccessLogs.sol \
        -Dtest
fi
