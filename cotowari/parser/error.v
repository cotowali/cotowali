module parser

import cotowari.errors { Err }
import cotowari.source { Pos }
import cotowari.token { Token, TokenKind }

enum RestoreStrategy {
	@none
	eol
}

fn (mut p Parser) error(msg string, pos Pos) IError {
	$if trace_parser ? {
		p.trace_begin(@FN, msg, '$pos')
		defer {
			p.trace_end()
		}
	}

	err := Err{
		source: p.file.source
		msg: msg
		pos: pos
	}
	p.file.errors << err
	return err
}

fn (mut p Parser) restore_from_syntax_error() {
	match p.restore_strategy {
		.@none {}
		.eol { p.skip_until_eol() }
	}
}

fn (mut p Parser) unexpected_token_error(found Token, expects ...TokenKind) IError {
	found_str := if found.text.len > 0 { found.text } else { found.kind.str() }
	if expects.len == 0 {
		return p.syntax_error('unexpected token `$found_str`', found.pos)
	}
	mut expect := 'expect '
	if expects.len == 1 {
		expect = '`$expects[0].str()`'
	} else {
		last := expects.last().str()
		expect = expects[..expects.len - 1].map(it.str()).join(', ') + ', or `$last`'
	}
	return p.syntax_error(expect + ', but found `$found_str`', found.pos)
}

fn (mut p Parser) syntax_error(msg string, pos Pos) IError {
	defer {
		p.file.has_syntax_error = true
		p.restore_from_syntax_error()
	}
	return p.error(msg, pos)
}

fn (mut p Parser) duplicated_error(name string, pos Pos) IError {
	return p.error('`$name` is duplicated', pos)
}
