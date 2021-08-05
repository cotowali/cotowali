// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module token

import cotowali.source { Pos }

pub enum TokenKind {
	unknown
	ident
	key_as
	key_assert
	key_else
	key_export
	key_fn
	key_for
	key_if
	key_in
	key_map
	key_require
	key_return
	key_struct
	key_use
	key_var
	key_while
	key_yield
	inline_shell
	colon
	comma
	hash
	dot
	dotdotdot
	amp
	question
	int_lit
	float_lit
	bool_lit
	single_quote
	single_quote_with_r_prefix
	double_quote
	double_quote_with_r_prefix
	string_lit_content_text
	string_lit_content_var
	string_lit_content_escaped_back_slash
	string_lit_content_escaped_single_quote
	string_lit_content_escaped_double_quote
	string_lit_content_escaped_dollar
	l_paren
	r_paren
	l_brace
	r_brace
	l_bracket
	r_bracket
	pipe
	plus
	minus
	div
	mul
	mod
	logical_and
	logical_or
	assign
	plus_assign
	minus_assign
	mul_assign
	div_assign
	mod_assign
	not
	eq
	ne
	gt
	ge
	lt
	le
	plus_plus
	minus_minus
	eol
	eof
}

[inline]
fn (k TokenKind) is_string_lit_content_escaped_char() bool {
	return k in [
		.string_lit_content_escaped_single_quote,
		.string_lit_content_escaped_back_slash,
	]
}

[inline]
fn (k TokenKind) is_op() bool {
	return k.is_prefix_op() || k.is_postfix_op() || k.is_infix_op() || k.is_assign_op()
}

[inline]
fn (k TokenKind) is_assign_op() bool {
	return k in [
		.assign,
		.plus_assign,
		.minus_assign,
		.mul_assign,
		.div_assign,
		.mod_assign,
	]
}

[inline]
fn (k TokenKind) is_comparsion_op() bool {
	return k in [
		.eq,
		.ne,
		.gt,
		.ge,
		.lt,
		.le,
	]
}

[inline]
fn (k TokenKind) is_logical_infix_op() bool {
	return k in [.logical_and, .logical_or]
}

[inline]
fn (k TokenKind) is_prefix_op() bool {
	return k in [
		.amp,
		.plus,
		.minus,
		.not,
	]
}

[inline]
fn (k TokenKind) is_postfix_op() bool {
	return k in [
		.plus_plus,
		.minus_minus,
	]
}

[inline]
fn (k TokenKind) is_infix_op() bool {
	return k.is_comparsion_op() || k.is_logical_infix_op()
		|| k in [.pipe, .plus, .minus, .mul, .div, .mod]
}

[inline]
fn (k TokenKind) is_literal() bool {
	return k in [
		.int_lit,
		.float_lit,
		.bool_lit,
	]
}

[inline]
fn (k TokenKind) is_keyword() bool {
	return k in [
		.key_as,
		.key_assert,
		.key_else,
		.key_export,
		.key_fn,
		.key_for,
		.key_if,
		.key_in,
		.key_map,
		.key_require,
		.key_return,
		.key_struct,
		.key_use,
		.key_var,
		.key_while,
		.key_yield,
	]
}

pub enum TokenKindClass {
	op
	assign_op
	comparsion_op
	infix_op
	logical_infix_op
	prefix_op
	postfix_op
	literal
	keyword
	string_lit_content_escaped_char
}

[inline]
pub fn (k TokenKind) @is(class TokenKindClass) bool {
	return match class {
		.op { k.is_op() }
		.assign_op { k.is_assign_op() }
		.comparsion_op { k.is_comparsion_op() }
		.logical_infix_op { k.is_logical_infix_op() }
		.infix_op { k.is_infix_op() }
		.prefix_op { k.is_prefix_op() }
		.postfix_op { k.is_postfix_op() }
		.literal { k.is_literal() }
		.keyword { k.is_keyword() }
		.string_lit_content_escaped_char { k.is_string_lit_content_escaped_char() }
	}
}

pub struct Token {
pub:
	kind TokenKind
	text string
	pos  Pos
}

pub type TokenCond = fn (Token) bool

pub fn (lhs Token) == (rhs Token) bool {
	return if lhs.pos.is_none() || rhs.pos.is_none() {
		lhs.kind == rhs.kind && lhs.text == rhs.text
	} else {
		lhs.kind == rhs.kind && lhs.text == rhs.text && lhs.pos == rhs.pos
	}
}

[inline]
fn (t Token) text_for_str() string {
	return t.text.replace_each(['\\', '\\\\', '\n', r'\n', '\r', r'\r'])
}

pub fn (t Token) str() string {
	return "Token{ .$t.kind, '$t.text_for_str()', $t.pos }"
}

pub fn (t Token) short_str() string {
	return "{ .$t.kind, '$t.text_for_str()' }"
}
