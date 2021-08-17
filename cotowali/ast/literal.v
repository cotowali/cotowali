// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos }
import cotowali.token { Token }
import cotowali.symbols { Scope, Type, builtin_type }

pub struct ArrayLiteral {
pub:
	pos Pos
pub mut:
	elem_typ Type
	scope    &Scope
	elements []Expr
}

fn (mut r Resolver) array_literal(mut expr ArrayLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.exprs(expr.elements)
	if expr.elements.len > 0 && expr.elem_typ == builtin_type(.placeholder) {
		expr.elem_typ = expr.elements[0].typ()
	}
}

pub struct MapLiteralEntry {
pub:
	key   Expr
	value Expr
}

pub struct MapLiteral {
pub:
	pos     Pos
	entries []MapLiteralEntry
pub mut:
	scope     &Scope
	key_typ   Type
	value_typ Type
}

fn (mut r Resolver) map_literal(mut expr MapLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	for entry in expr.entries {
		r.expr(entry.key)
		r.expr(entry.value)
	}
	if expr.entries.len > 0 {
		entry := expr.entries[0]
		if expr.key_typ == builtin_type(.placeholder) {
			expr.key_typ = entry.key.typ()
		}
		if expr.value_typ == builtin_type(.placeholder) {
			expr.value_typ = entry.value.typ()
		}
	}
}

pub struct PrimitiveLiteral {
pub:
	scope &Scope
	token Token
}

pub type BoolLiteral = PrimitiveLiteral
pub type IntLiteral = PrimitiveLiteral
pub type FloatLiteral = PrimitiveLiteral

pub fn (e BoolLiteral) bool() bool {
	return e.token.text != 'false'
}

fn (mut r Resolver) bool_literal(expr BoolLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

fn (mut r Resolver) int_literal(expr IntLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

fn (mut r Resolver) float_literal(expr FloatLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

pub type StringLiteralContent = Expr | Token

pub fn (c StringLiteralContent) is_const() bool {
	return if c is Token { c.kind == .string_literal_content_text } else { false }
}

pub struct StringLiteral {
pub:
	scope    &Scope
	open     Token
	contents []StringLiteralContent
	close    Token
}

pub fn (s &StringLiteral) is_const() bool {
	return s.contents.all(it.is_const())
}

pub fn (s &StringLiteral) is_raw() bool {
	return s.open.kind in [.single_quote_with_r_prefix, .double_quote_with_r_prefix]
}

fn (mut r Resolver) string_literal(expr StringLiteral) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	for content in expr.contents {
		if content is Expr {
			r.expr(content)
		}
	}
}