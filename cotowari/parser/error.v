module parser

import cotowari.errors { Err }

type ErrorValue = Err | errors.ErrorWithPos | string

fn (mut p Parser) error(v ErrorValue) IError {
	tok := p.consume()
	err := match v {
		string {
			Err{
				source: p.file.source
				msg: v
				pos: tok.pos
			}
		}
		errors.ErrorWithPos {
			Err{
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
	p.file.errors << err
	return IError(err)
}

fn (mut p Parser) duplicated_error(name string) IError {
	return p.error('`$name` is duplicated')
}

fn error_node(err IError) &Err {
	if err is errors.Err {
		return err
	}
	panic(err)
}
