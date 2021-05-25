module parser

import cotowari.errors { Err }
import cotowari.source { Pos }
import cotowari.token { Token, TokenKind }

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

fn (mut p Parser) unexpected_token_error(found Token, expects ...TokenKind) IError {
	if expects.len == 0 {
		return p.error('unexpected token `$found.text`', found.pos)
	}
	mut expect := 'expect '
	if expects.len == 1 {
		expect = '`$expects[0].str()`'
	} else {
		expect = expects[..expects.len - 1].map(it.str()).join(', ') + ', or `$expects.last()`'
	}
	return p.error(expect + ', but found `$found.text`', found.pos)
}

fn (mut p Parser) duplicated_error(name string, pos Pos) IError {
	return p.error('`$name` is duplicated', pos)
}
