#!/bin/bash
START_PRODUCTION="START OF PRODUCTION CODE"
END_PRODUCTION="END OF PRODUCTION CODE"
START_MOCK="START OF MOCK CODE"
END_MOCK="END OF MOCK CODE"
TEMPLATE_FILE="templates/AccessLogs.sol.template"
TARGET_FILE="src/AccessLogs.sol"

if [ "$1" == "-h" ] || ([ "$1" != "prod" ] && [ "$1" != "mock" ] && [ $# -gt 0 ] ) || [ $# -gt 1 ]; then
  echo "Usage: `basename $0` <prod|mock>"
  exit 0
fi

start_prod=`cat "$TEMPLATE_FILE" | grep "$START_PRODUCTION" -n | grep -Eo "[0-9]*"`
end_prod=`cat "$TEMPLATE_FILE" | grep "$END_PRODUCTION" -n | grep -Eo "[0-9]*"`
start_mock=`cat "$TEMPLATE_FILE" | grep "$START_MOCK" -n | grep -Eo "[0-9]*"`
end_mock=`cat "$TEMPLATE_FILE" | grep "$END_MOCK" -n | grep -Eo "[0-9]*"`

if [ "$1" == "prod" ] || [ $# -eq 0 ]; then
    sed -e "${start_mock},${end_mock}d;${start_prod}d;${end_prod}d;" $TEMPLATE_FILE > $TARGET_FILE
else
    sed -e "${start_prod},${end_prod}d;${start_mock}d;${end_mock}d;" $TEMPLATE_FILE > $TARGET_FILE
fi
