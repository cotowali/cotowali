// Copyright (c) 2021-2023 zakuro <z@kuro.red>
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
	key_break
	key_const
	key_continue
	key_else
	key_export
	key_fn
	key_for
	key_if
	key_in
	key_map
	key_module
	key_null
	key_nameof
	key_require
	key_return
	key_type
	key_typeof
	key_var
	key_while
	key_yield
	compiler_directive
	colon
	coloncolon
	semicolon
	comma
	hash
	dot
	dotdotdot
	amp
	bar
	question
	int_literal
	float_literal
	bool_literal
	single_quote
	single_quote_with_r_prefix
	single_quote_with_at_prefix
	double_quote
	double_quote_with_r_prefix
	double_quote_with_at_prefix
	inline_shell_content_text
	inline_shell_content_var
	inline_shell_content_expr_substitution_open
	inline_shell_content_expr_substitution_close
	string_literal_content_text
	string_literal_content_back_quote
	string_literal_content_hex
	string_literal_content_glob
	string_literal_content_var
	string_literal_content_expr_open
	string_literal_content_expr_close
	string_literal_content_escaped_back_slash
	string_literal_content_escaped_newline
	string_literal_content_escaped_single_quote
	string_literal_content_escaped_double_quote
	string_literal_content_escaped_dollar
	doc_comment
	l_paren
	r_paren
	l_brace
	r_brace
	l_bracket
	r_bracket
	pipe
	pipe_append
	plus
	minus
	div
	mul
	mod
	pow
	logical_and
	logical_or
	assign
	plus_assign
	minus_assign
	mul_assign
	div_assign
	mod_assign
	pow_assign
	not
	eq
	ne
	gt
	ge
	lt
	le
	plusplus
	minusminus
	eol
	eof
}

pub fn (k TokenKind) str_for_ident() string {
	return if k.@is(.op) {
		'__${k}__'
	} else if k == .key_as {
		'as'
	} else {
		k.str()
	}
}

pub fn token_kinds(class TokenKindClass) []TokenKind {
	kinds := fn (kinds []TokenKind) []TokenKind {
		return kinds
	}

	return match class {
		.op {
			v1 := token_kinds(.assign_op)
			v2 := token_kinds(.infix_op)
			v3 := token_kinds(.prefix_op)
			v4 := token_kinds(.postfix_op)
			mut list := []TokenKind{cap: v1.len + v2.len + v3.len + v4.len}
			list << v1
			list << v2
			list << v3
			list << v4
			list
		}
		.assign_op {
			kinds([
				.assign,
				.plus_assign,
				.minus_assign,
				.mul_assign,
				.div_assign,
				.mod_assign,
			])
		}
		.comparsion_op {
			kinds([
				.eq,
				.ne,
				.gt,
				.ge,
				.lt,
				.le,
			])
		}
		.logical_infix_op {
			kinds([.logical_and, .logical_or])
		}
		.prefix_op {
			kinds([
				.amp,
				.plus,
				.minus,
				.not,
			])
		}
		.postfix_op {
			kinds([
				.plusplus,
				.minusminus,
			])
		}
		.infix_op {
			v1 := kinds([
				.key_as,
				.pipe_append,
				.pipe,
				.plus,
				.minus,
				.mul,
				.div,
				.mod,
				.pow,
			])
			v2 := token_kinds(.comparsion_op)
			v3 := token_kinds(.logical_infix_op)
			mut list := []TokenKind{cap: v1.len + v2.len + v3.len}
			list << v1
			list << v2
			list << v3
			list
		}
		.literal {
			kinds([
				.int_literal,
				.float_literal,
				.bool_literal,
			])
		}
		.keyword {
			kinds([
				.key_as,
				.key_const,
				.key_else,
				.key_export,
				.key_fn,
				.key_for,
				.key_if,
				.key_in,
				.key_map,
				.key_module,
				.key_nameof,
				.key_require,
				.key_return,
				.key_type,
				.key_typeof,
				.key_var,
				.key_while,
				.key_yield,
			])
		}
		.string_literal_content_escaped_char {
			kinds([
				.string_literal_content_escaped_single_quote,
				.string_literal_content_escaped_back_slash,
			])
		}
	}
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
	string_literal_content_escaped_char
}

[inline]
pub fn (k TokenKind) @is(class TokenKindClass) bool {
	return k in token_kinds(class)
}

pub enum KeywordIdent {
	not_a_keyword_ident
	assert_
	sh
	pwsh
	inline
}

pub fn (t Token) keyword_ident() KeywordIdent {
	if t.kind == .ident {
		match t.text {
			'assert' { return .assert_ }
			'sh' { return .sh }
			'pwsh' { return .pwsh }
			'inline' { return .inline }
			else { return .not_a_keyword_ident }
		}
	}
	return .not_a_keyword_ident
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

pub fn (t Token) bool() bool {
	return t.kind == .bool_literal && t.text != 'false'
}

pub fn (t Token) str() string {
	return "Token{ .${t.kind}, '${t.text_for_str()}', ${t.pos} }"
}

pub fn (t Token) short_str() string {
	return "{ .${t.kind}, '${t.text_for_str()}' }"
}
