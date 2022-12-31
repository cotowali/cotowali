// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module messages

import cotowali.util.checksum
import cotowali.util { Either }

[params]
pub struct Expects[T] {
	expects []T
}

[params]
pub struct ExpectedActual[T, J] {
	expected T [required]
	actual   J [required]
}

pub enum SymbolKind {
	compiler_variable
	typ
	variable
	function
	method
	mod
	operator
}

pub fn (k SymbolKind) str() string {
	return match k {
		.compiler_variable { 'compiler variable' }
		.typ { 'type' }
		.variable { 'variable' }
		.function { 'function' }
		.method { 'method' }
		.mod { 'module' }
		.operator { 'operator' }
	}
}

[inline]
pub fn already_defined(kind SymbolKind, name string) string {
	return '${kind} `${name}` is already defined'
}

[inline]
pub fn undefined(kind SymbolKind, name string) string {
	return '${kind} `${name}` is not defined'
}

pub fn invalid_key(key string, v Expects[string]) string {
	return 'invalid key `${key}`' + (match v.expects.len {
		0 {
			''
		}
		1 {
			', expecting `${v.expects.first()}`'
		}
		2 {
			', expecting `${v.expects.first()}` or `${v.expects.last()}`'
		}
		else {
			quoted_strs := v.expects.map('`${it}`')
			', expecting ${quoted_strs[..quoted_strs.len - 1].join(', ')}, or ${quoted_strs.last()}'
		}
	})
}

[inline]
pub fn duplicated_key(key string) string {
	return 'duplicated key `${key}`'
}

pub fn args_count_mismatch(v ExpectedActual[Either[string, int], int]) string {
	expected := match v.expected {
		string { v.expected }
		int { v.expected.str() }
	}
	return 'expected ${expected} arguments, but got ${v.actual}'
}

[inline]
pub fn checksum_mismatch(algo checksum.Algorithm, v ExpectedActual[string, string]) string {
	return '${algo} checksum mismatch: ${v.expected} (expected) != ${v.actual} (actual)'
}
