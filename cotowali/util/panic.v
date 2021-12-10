// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

[noreturn]
pub fn li_panic<T>(file string, line string, err T) {
	li_hash := $env('COTOWALI_HASH')
	msg := 'cotowali panic: $err
	location: $file:$line
	v_hash: ${@VHASH}
	cotowali_hash: $li_hash

This is compiler bug. Please report it on GitHub issue.
https://github.com/cotowali/cotowali/issues/new?labels=bug&template=bug_report.md'

	$if debug {
		panic(msg)
	} $else {
		eprintln(msg)
		exit(1)
	}
	for {}
}
