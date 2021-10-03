# start: builtin/array.sh
#
# Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

array_to_str() {
  name=$1
  echo "$( eval echo $(array_elements $name) )"
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
  eval "${name}_$i='$val'"
}

array_len() {
  name="$1"
  eval "echo \$${name}_len"
}

array_elements() {
  name=$1
  len="$(array_len $name)"

  i=0
  while [ "$i" -lt "$len" ]
  do
    elem="${name}_$i"
    printf '"$%s"' "$elem"
    if [ "$i" -ne "$(( len - 1 ))" ]
    then
      printf ' '
    fi
    i=$((i + 1))
  done
}

array_assign() {
  name=$1
  shift
  len="$#"
  eval "${name}_len=$len"

  i=0
  while [ "$i" -lt "$len" ]
  do
    array_set "$name" "$i" "$(eval echo "\$$(( i + 1 ))")"
    i=$((i + 1))
  done
}

array_init() {
  name=$1
  len=$2
  value=$3

  eval "${name}_len=$len"
  i=0
  while [ "$i" -lt "$len" ]
  do
    array_set "$name" "$i" "$value"
    i=$((i + 1))
  done
}

array_copy() {
  dest_name="$1"
  src_name="$2"
  len="$(array_len $src_name)"
  eval "${dest_name}_len=$len"

  i=0
  while [ "$i" -lt "$len" ]
  do
    array_set "$dest_name" "$i" "$(array_get "$src_name" $i)"
    i=$((i + 1))
  done
}

# end: builtin/array.sh
