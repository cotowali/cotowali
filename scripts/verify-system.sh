#!/bin/sh
# TODO: replace with cotowari

fail=""
if ! which z > /dev/null
then
  fail="1"
  echo "z not found" 1>&2
elif ! z --verify-config > /dev/null 2>&1
then
  fail="1"
  echo "z is too old. Update z" 1>&2
fi

if ! which v > /dev/null
then
  fail="1"
  echo "v not found" 1>&2
fi

if [ "$fail" = "1" ]
then
  echo "Faild to verify system. See README.md"
  exit 1
fi
