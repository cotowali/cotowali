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
	pos            Pos
	is_init_syntax bool // is `[]Type{init: v, len: n}` syntax
pub mut:
	len      Expr
	init     Expr
	elem_typ Type
	scope    &Scope
	elements []Expr
}

[inline]
pub fn (expr &ArrayLiteral) children() []Node {
	return expr.elements.map(Node(it))
}

fn (mut r Resolver) array_literal(mut expr ArrayLiteral, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	if expr.is_init_syntax {
		r.expr(mut expr.init, opt)
		r.expr(mut expr.len, opt)
	} else {
		r.exprs(mut expr.elements, opt)
	}
	if expr.elements.len > 0 && expr.elem_typ == builtin_type(.placeholder) {
		expr.elem_typ = expr.elements[0].typ()
	}
}

pub struct MapLiteralEntry {
pub mut:
	key   Expr
	value Expr
}

pub struct MapLiteral {
pub:
	pos Pos
pub mut:
	entries   []MapLiteralEntry
	scope     &Scope
	key_typ   Type
	value_typ Type
}

pub fn (expr &MapLiteral) children() []Node {
	mut children := []Node{cap: expr.entries.len * 2}
	for e in expr.entries {
		children << e.key
		children << e.value
	}
	return children
}

fn (mut r Resolver) map_literal(mut expr MapLiteral, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	for mut entry in expr.entries {
		r.expr(mut entry.key, opt)
		r.expr(mut entry.value, opt)
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
pub type NullLiteral = PrimitiveLiteral

pub fn (e BoolLiteral) bool() bool {
	return e.token.bool()
}

pub fn (e IntLiteral) int() int {
	return e.token.text.int()
}

fn (mut r Resolver) bool_literal(expr BoolLiteral, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

fn (mut r Resolver) int_literal(expr IntLiteral, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

fn (mut r Resolver) float_literal(expr FloatLiteral, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
}

fn (mut r Resolver) null_literal(expr NullLiteral, opt ResolveExprOpt) {
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
pub mut:
	scope &Scope
pub:
	open     Token
	contents []StringLiteralContent
	close    Token
}

pub fn (s &StringLiteral) pos() Pos {
	return s.open.pos.merge(s.close.pos)
}

pub fn (s StringLiteral) typ() Type {
	str := builtin_type(.string)
	return if s.is_glob() {
		unsafe { s.scope.lookup_or_register_array_type(elem: str).typ }
	} else {
		str
	}
}

pub fn (s &StringLiteral) is_const() bool {
	return s.contents.all(it.is_const())
}

pub fn (s &StringLiteral) const_text() ?string {
	if !s.is_const() {
		return error('string literal is not a const')
	}
	return s.contents.map((it as Token).text).join('')
}

pub fn (s &StringLiteral) is_raw() bool {
	return s.open.kind in [.single_quote_with_r_prefix, .double_quote_with_r_prefix]
}

pub fn (s &StringLiteral) is_glob() bool {
	return s.open.kind in [.single_quote_with_at_prefix, .double_quote_with_at_prefix]
}

[inline]
fn (s &StringLiteral) children() []Node {
	return s.contents.filter(it is Expr).map(Node(it as Expr))
}

fn (mut r Resolver) string_literal(mut expr StringLiteral, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	for mut content in expr.contents {
		if mut content is Expr {
			r.expr(mut content, opt)
		}
	}
}
