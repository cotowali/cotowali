// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module messages

import cotowali.util.checksum

[params]
pub struct Expects<T> {
	expects []T
}

[params]
pub struct ExpectedActual<T, J> {
	expected T [required]
	actual   J [required]
}

pub enum SymbolKind {
	typ
	variable
	function
	method
	namespace
	operator
}

pub fn (k SymbolKind) str() string {
	return match k {
		.typ { 'type' }
		.variable { 'variable' }
		.function { 'function' }
		.method { 'method' }
		.namespace { 'namespace' }
		.operator { 'operator' }
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

pub fn invalid_key(key string, v Expects<string>) string {
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

[inline]
pub fn checksum_mismatch(algo checksum.Algorithm, v ExpectedActual<string, string>) string {
	return '$algo checksum mismatch: $v.expected (expected) != $v.actual (actual)'
}

pub enum OpNotation {
	infix
	prefix
	postfix
}

fn (v OpNotation) str() string {
	return match v {
		.infix { 'infix' }
		.prefix { 'prefix' }
		.postfix { 'postfix' }
	} + ' operator'
}

pub fn invalid_operator_kind(expected OpNotation, op_text string) string {
	return '`$op_text` is not $expected'
}

pub enum OpSignatureErrorKind {
	parameters_count
	variadic
	have_pipe_in
}

pub fn invalid_operator_signature(err_kind OpSignatureErrorKind, op OpNotation) string {
	s := '$op ${SymbolKind.function}'
	return match err_kind {
		.parameters_count {
			params := if op == .infix { '2 parameters' } else { '1 parameter' }
			'$s must have $params'
		}
		.variadic {
			'$s cannot be variadic'
		}
		.have_pipe_in {
			'$s cannot have pipe in'
		}
	}
}
