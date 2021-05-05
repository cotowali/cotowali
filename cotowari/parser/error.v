module parser

import cotowari.errors { unreachable }
import cotowari.token { Token }

fn (p &Parser) value_to_err<T>(v T, tok Token) errors.Err {
	$if T is string {
		return errors.Err{
			source: p.file.source
			msg: v
			pos: tok.pos
		}
	} $else $if T is errors.ErrorWithPos {
		return errors.Err{
			source: p.file.source
			msg: v.msg
			pos: v.pos
			code: v.code
		}
	} $else $if T is errors.Err {
		return v
	} $else {
		panic(unreachable)
	}
}

fn (mut p Parser) error<T>(v T) IError {
	tok := p.consume()
	err := p.value_to_err(v, tok)
	p.file.errors << err
	return err
}

fn (mut p Parser) duplicated_error(name string) IError {
	return p.error('`$name` is duplicated')
}
