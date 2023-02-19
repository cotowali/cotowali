// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sh

fn (mut e Emitter) builtin() {
	e.writeln(sh.builtin)
}

const builtin = [
	'
# -- start builtin --
#
# Copyright (c) 2021-2023 zakuro <z@kuro.red>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
',
	'
cotowali_true_value() {
	echo ${true_value}
}

cotowali_false_value() {
	echo ${false_value}
}
',
	'
array_to_str() {
  name=\${1}
  echo "\$( eval echo \$(array_elements \$name) )"
}

array_get() {
  name=\${1}
  i=\${2}
  eval echo "\\\$\${name}_\$i"
}

array_set() {
  name=\${1}
  i=\${2}
  val=\${3}
  eval "\${name}_\$i=\'\$val\'"
}

array_push() {
	name=\${1}
	value=\${2}

	array_set \$name \$(( \${name}_len )) "\$value"
  eval "\${name}_len=\$(( \${name}_len + 1 ))"
}

array_push_array() {
  name="\${1}"
  values_name="\${2}"
	values_len=\$(( \${values_name}_len ))

  push_array_i=0
  while [ "\$push_array_i" -lt "\$values_len" ]
  do
		array_push "\$name" "\$(array_get \$values_name \$push_array_i)"
    push_array_i=\$((push_array_i + 1))
  done
}

array_len() {
  name="\${1}"
  eval "echo \\\$\${name}_len"
}

array_elements() {
  name=\${1}
  len="\$(array_len \$name)"

  i=0
  while [ "\$i" -lt "\$len" ]
  do
    elem="\${name}_\$i"
    printf \'"\$%s"\' "\$elem"
    if [ "\$i" -ne "\$(( len - 1 ))" ]
    then
      printf \' \'
    fi
    i=\$((i + 1))
  done
}

array_assign() {
  name=\${1}
  shift
  len="\$#"
  eval "\${name}_len=\$len"

  i=0
  while [ "\$i" -lt "\$len" ]
  do
    array_set "\$name" "\$i" "\$(eval echo "\\\$\$(( i + 1 ))")"
    i=\$((i + 1))
  done
}

array_init() {
  name=\${1}
  len=\${2}
  value=\${3}

  eval "\${name}_len=\$len"
  i=0
  while [ "\$i" -lt "\$len" ]
  do
    array_set "\$name" "\$i" "\$value"
    i=\$((i + 1))
  done
}

array_copy() {
  dest_name="\${1}"
  src_name="\${2}"
  len="\$(array_len \$src_name)"
  eval "\${dest_name}_len=\$len"

  i=0
  while [ "\$i" -lt "\$len" ]
  do
    array_set "\$dest_name" "\$i" "\$(array_get "\$src_name" \$i)"
    i=\$((i + 1))
  done
}

map_keys_var() {
  echo "__cotowali_meta_map_keys_\${1}"
}

map_keys() {
  eval echo "\\\$\$(map_keys_var \${1})"
}

map_entries() {
  name="\${1}"
  for key in \$(map_keys \$name)
  do
    printf
  done
}

map_copy() {
  dst="\${1}"
  src="\${2}"
  for key in \$(map_keys "\$src")
  do
    value="\$(map_get "\$src" "\$key")"
    map_set "\$dst" "\$key" "\$value"
  done
}

map_get() {
  name=\${1}
  key=\${2}
  eval echo "\\\$\${name}_\$key"
}

map_set() {
  name=\${1}
  key=\${2}
  value=\${3}
  eval "\${name}_\$key=\$value"
  eval "\$(map_keys_var \$name)=\\"\$({ map_keys \$name; echo \$key; } | sort | uniq )\\""
}

# -- end builtin --
',
].join('\n')
