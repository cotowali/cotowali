// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.token { TokenKind }
import cotowali.ast
import cotowali.errors { unreachable }

fn (mut p Parser) parse_string_literal() ?ast.StringLiteral {
	tok := p.check(.single_quote, .double_quote, .single_quote_with_r_prefix, .double_quote_with_r_prefix) ?
	match tok.kind {
		.single_quote { return p.parse_single_quote_string_literal() }
		.double_quote { return p.parse_double_quote_string_literal() }
		.single_quote_with_r_prefix { return p.parse_raw_string_literal(.single_quote) }
		.double_quote_with_r_prefix { return p.parse_raw_string_literal(.double_quote) }
		else { panic(unreachable('expected quote')) }
	}
	panic(unreachable('expected quote'))
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

	content := p.consume_with_check(.string_lit_content_text) ?
	close := p.consume_with_check(quote) ?
	return ast.StringLiteral{
		scope: p.scope
		open: open
		contents: [ast.StringLiteralContent(content)]
		close: close
	}
}

fn (mut p Parser) parse_single_quote_string_literal() ?ast.StringLiteral {
	open := p.consume_with_assert(.single_quote)

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
			.string_lit_content_text, .string_lit_content_escaped_back_slash,
			.string_lit_content_escaped_single_quote {
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
	open := p.consume_with_assert(.double_quote)

	if close := p.consume_if_kind_eq(.double_quote) {
		return ast.StringLiteral{
			scope: p.scope
			open: open
			close: close
		}
	}

	mut contents := []ast.StringLiteralContent{}
	for {
		match p.kind(0) {
			.string_lit_content_text, .string_lit_content_escaped_dollar {
				contents << p.consume()
			}
			.string_lit_content_var {
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
