// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module messages

pub enum SymbolKind {
	typ
	variable
	function
	method
	namespace
}

pub fn (k SymbolKind) str() string {
	return match k {
		.typ { 'type' }
		.variable { 'variable' }
		.function { 'function' }
		.method { 'method' }
		.namespace { 'namespace' }
	}
}

[inline]
pub fn unreachable<T>(err T) string {
	return 'unreachable - This is a compiler bug (err: $err).'
}

[inline]
pub fn already_defined(kind SymbolKind, name string) string {
	return '$kind `$name` is already defined'
}

[inline]
pub fn undefined(kind SymbolKind, name string) string {
	return '$kind `$name` is not defined'
}

[params]
pub struct ParamsForInvalid {
	expects []string
}

pub fn invalid_key(key string, v ParamsForInvalid) string {
	return 'invalid key `$key`' + (match v.expects.len {
		0 {
			''
		}
		1 {
			', expecting `$v.expects.first()`'
		}
		2 {
			', expecting `$v.expects.first()` or `$v.expects.last()`'
		}
		else {
			quoted_strs := v.expects.map('`$it`')
			', expecting ${quoted_strs[..quoted_strs.len - 1].join(', ')}, or $quoted_strs.last()'
		}
	})
}

[inline]
pub fn duplicated_key(key string) string {
	return 'duplicated key `$key`'
}
