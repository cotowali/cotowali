# start: builtin/map.sh
#
# Copyright (c) 2021 The Cotowali Authors. All rights reserved.
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


map_keys_var() {
  echo "__cotowali_meta_map_keys_$1"
}

map_keys() {
  eval echo "\$$(map_keys_var $1)"
}

map_entries() {
  name="$1"
  for key in $(map_keys $name)
  do
    printf
  done
}

map_copy() {
  dst="$1"
  src="$2"
  for key in $(map_keys "$src")
  do
    value="$(map_get "$src" "$key")"
    map_set "$dst" "$key" "$value"
  done
}

map_get() {
  name=$1
  key=$2
  eval echo "\$${name}_$key"
}

map_set() {
  name=$1
  key=$2
  value=$3
  eval "${name}_$key=$value"
  eval "$(map_keys_var $name)=\"$({ map_keys $name; echo $key; } | sort | uniq )\""
}

# end: builtin/map.sh
