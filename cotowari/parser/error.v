module parser

import cotowari.errors
import cotowari.token { Token }

type ErrorValue = errors.Err | errors.ErrorWithPos | string

fn (v ErrorValue) to_err(p &Parser, tok Token) errors.Err {
	return match v {
		string {
			errors.Err{
				source: p.file.source
				msg: v
				pos: tok.pos
			}
		}
		errors.ErrorWithPos {
			errors.Err{
				source: p.file.source
				msg: v.msg
				pos: v.pos
				code: v.code
			}
		}
		errors.Err {
			v
		}
	}
}

fn (mut p Parser) error(v ErrorValue) IError {
	tok := p.consume()
	err := v.to_err(p, tok)
	p.file.errors << err
	return IError(err)
}

fn (mut p Parser) duplicated_error(name string) IError {
	return p.error('`$name` is duplicated')
}
