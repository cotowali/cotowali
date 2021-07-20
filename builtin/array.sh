# start: builtin/array.sh
#
# Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

str_to_array() {
  str_val=$1
  name=$2
  eval "${name}_len=0"
  i=0
  for v in $str_val
  do
    eval "${name}_len=$(( ${name_len} + 1 ))"
    eval "${name}_$i=$v"
    i=$(( i + 1 ))
  done
}

array_to_str() {
  name=$1
  len="$(eval echo "${name}_len")"
  for i in $(seq 0 $(( len - 1 )) )
  do
    eval echo "\$${name}_$i"
  done
}

array_get() {
  name=$1
  i=$2
  eval echo "\$${name}_$i"
}

array_set() {
  name=$1
  i=$2
  val=$3
  eval "${name}_$i=$val"
}

array_elements() {
  name=$1
  len="$(eval "echo \$${name}_len" )"
  for i in $(seq 0 $(( len - 1 )) )
  do
    elem="${name}_$i"
    printf '"$%s"' "$elem"
    if [ "$i" -ne "$(( len - 1 ))" ]
    then
      printf ' '
    fi
  done
}

array_assign() {
  name=$1
  shift
  len="$#"
  eval "${name}_len=$len"
  for i in $(seq 0 $(( len - 1 )) )
  do
    array_set "$name" "$i" "$(eval echo "\$$(( i + 1 ))")"
  done
}

# end: builtin/array.sh
