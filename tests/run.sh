#!/bin/sh
basedir=$(cd $(dirname $0); pwd)
exit_code=0

is_fail_test() {
  [ "$1" = "$basedir/assert.sh" ] \
    || [ "$1" = "$basedir/test_runner_test.sh" ] \
    || [ "$1" = "$basedir/std/require_command.sh" ]
}

success() {
  printf '[ OK ] %s\n' "$1"
}
fail() {
  printf '[FAIL] %s\n' "$1"
  exit_code=1
}

for f in $basedir/*.sh $basedir/**/*.sh
do
  if [ "$f" = "$basedir/run.sh" ]
  then
    # skip this file
    continue
  fi

  if sh $f
  then
    if is_fail_test "$f"
    then
      fail "$f"
    else
      success "$f"
    fi
  else
    if is_fail_test "$f"
    then
      success "$f"
    else
      fail "$f"
    fi
  fi
done

exit $exit_code
