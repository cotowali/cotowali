// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module compiler_directives

pub enum CompilerDirectiveKind {
	error
	warning
}

pub fn compiler_directive_kind_from_name(name string) ?CompilerDirectiveKind {
	match name {
		'error' { return .error }
		'warning' { return .warning }
		else { return error('unknown compiler directive `#$name`') }
	}
}
