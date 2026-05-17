#!/bin/sh
set -e
set -x

# PROJECT_SERIAL and PROJECT_BAUDRATE can be redefined by user before calling this script
: "${PROJECT_SERIAL:=/dev/ttyACM0}"
: "${PROJECT_BAUDRATE:=115200}"

# Check if serial port is already in use
if fuser "${PROJECT_SERIAL}" >/dev/null 2>&1; then
  echo "${PROJECT_SERIAL} is already in use by another process."
  exit 1
fi

# Configure Serial link
stty -F "${PROJECT_SERIAL}" raw -echo -echoctl -echoe -echok -echonl -echoprt && stty -F "${PROJECT_SERIAL}" "${PROJECT_BAUDRATE}" cs8 -cstopb -parenb

# Live Log
ts "[%H:%M:%S]" <"${PROJECT_SERIAL}"
