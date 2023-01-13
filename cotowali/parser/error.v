// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.errors
import cotowali.source { Pos }
import cotowali.token { Token, TokenKind }
import term

enum RestoreStrategy {
	@none
	eol
}

fn (mut p Parser) warn(msg string, pos Pos) IError {
	$if trace_parser ? {
		p.trace_begin(term.warn_message(@FN), msg, '${pos}')
		defer {
			p.trace_end()
		}
	}

	return p.ctx.errors.push_warn(msg: msg, pos: pos)
}

fn (mut p Parser) error(msg string, pos Pos) IError {
	$if trace_parser ? {
		p.trace_begin(term.fail_message(@FN), msg, '${pos}')
		defer {
			p.trace_end()
		}
	}

	return p.ctx.errors.push_err(msg: msg, pos: pos)
}

fn (mut p Parser) syntax_error(msg string, pos Pos) IError {
	$if trace_parser ? {
		p.trace_begin(term.fail_message(@FN), msg, '${pos}')
		defer {
			p.trace_end()
		}
	}

	p.restore_from_syntax_error()
	return p.ctx.errors.push_err(msg: msg, pos: pos, is_syntax_error: true)
}

fn (mut p Parser) restore_from_syntax_error() {
	match p.restore_strategy {
		.@none {}
		.eol {
			p.skip_until_eol_or_semicolon()
			p.skip_eol_and_semicolon()
		}
	}
}

fn (mut p Parser) unexpected_token_error(found Token, expects ...TokenKind) IError {
	$if trace_parser ? {
		p.trace_begin(@FN, '${found}', ...expects.map(it.str()))
		defer {
			p.trace_end()
		}
	}

	found_str := if found.text.len > 0 { found.text } else { found.kind.str() }
	mut msg := 'unexpected token `${found_str}`'
	if expects.len == 0 {
		return p.syntax_error(msg, found.pos)
	}

	msg += ', expecting '
	if expects.len == 1 {
		msg += '`${expects[0].str()}`'
	} else {
		last := expects.last().str()
		msg += expects[..expects.len - 1].map(it.str()).join(', ') + ' or `${last}`'
	}
	return p.syntax_error(msg, found.pos)
}
