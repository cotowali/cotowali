// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.ast
import cotowali.token { TokenKind }
import cotowali.util { li_panic }

fn (mut p Parser) parse_string_literal() ?ast.StringLiteral {
	tok := p.check(.single_quote, .double_quote, .single_quote_with_r_prefix, .double_quote_with_r_prefix,
		.single_quote_with_at_prefix, .double_quote_with_at_prefix) ?
	match tok.kind {
		.single_quote { return p.parse_single_quote_string_literal() }
		.double_quote { return p.parse_double_quote_string_literal() }
		.single_quote_with_at_prefix { return p.parse_single_quote_string_literal() }
		.double_quote_with_at_prefix { return p.parse_double_quote_string_literal() }
		.single_quote_with_r_prefix { return p.parse_raw_string_literal(.single_quote) }
		.double_quote_with_r_prefix { return p.parse_raw_string_literal(.double_quote) }
		else { li_panic(@FILE, @LINE, 'expected quote') }
	}
	li_panic(@FILE, @LINE, 'expected quote')
}

fn (mut p Parser) parse_raw_string_literal(quote TokenKind) ?ast.StringLiteral {
	open := p.consume_with_assert(.single_quote_with_r_prefix, .double_quote_with_r_prefix)

	if close := p.consume_if_kind_eq(quote) {
		return ast.StringLiteral{
			scope: p.scope
			open: open
			close: close
		}
	}

	content := p.consume_with_check(.string_literal_content_text) ?
	close := p.consume_with_check(quote) ?
	return ast.StringLiteral{
		scope: p.scope
		open: open
		contents: [ast.StringLiteralContent(content)]
		close: close
	}
}

fn (mut p Parser) parse_single_quote_string_literal() ?ast.StringLiteral {
	open := p.consume_with_assert(.single_quote, .single_quote_with_at_prefix)

	if close := p.consume_if_kind_eq(.single_quote) {
		return ast.StringLiteral{
			scope: p.scope
			open: open
			close: close
		}
	}

	mut contents := []ast.StringLiteralContent{}
	for {
		match p.kind(0) {
			.string_literal_content_text, .string_literal_content_glob,
			.string_literal_content_escaped_back_slash,
			.string_literal_content_escaped_single_quote {
				contents << p.consume()
			}
			else {
				break
			}
		}
	}
	close := p.consume_with_check(.single_quote) ?
	return ast.StringLiteral{
		scope: p.scope
		open: open
		contents: contents
		close: close
	}
}

fn (mut p Parser) parse_double_quote_string_literal() ?ast.StringLiteral {
	open := p.consume_with_assert(.double_quote, .double_quote_with_at_prefix)

	if close := p.consume_if_kind_eq(.double_quote) {
		return ast.StringLiteral{
			scope: p.scope
			open: open
			close: close
		}
	}

	mut contents := []ast.StringLiteralContent{}

	for {
		if tok := p.consume_if_kind_eq(.string_literal_content_var) {
			name := tok.text[1..] // trim $ prefix
			v := ast.Var{
				ident: ast.Ident{
					scope: p.scope
					text: name
					pos: tok.pos
				}
			}

			contents << ast.Expr(v)
			continue
		}
		if _ := p.consume_if_kind_eq(.string_literal_content_expr_open) {
			contents << p.parse_expr(.toplevel) ?
			p.consume_with_check(.string_literal_content_expr_close) ?
			continue
		}
		match p.kind(0) {
			.string_literal_content_text, .string_literal_content_hex,
			.string_literal_content_back_quote, .string_literal_content_glob,
			.string_literal_content_escaped_dollar, .string_literal_content_escaped_back_slash,
			.string_literal_content_escaped_double_quote, .string_literal_content_escaped_newline {
				contents << p.consume()
			}
			.string_literal_content_var {
				contents << p.parse_ident() ?
			}
			else {
				break
			}
		}
	}

	close := p.consume_with_check(.double_quote) ?

	return ast.StringLiteral{
		scope: p.scope
		open: open
		contents: contents
		close: close
	}
}
