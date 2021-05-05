module parser

import cotowari.errors { Err }

fn (mut p Parser) error(msg string) IError {
	tok := p.consume()
	err := Err{
		source: p.file.source
		msg: msg
		pos: tok.pos
	}
	p.file.errors << err
	return err
}

fn (mut p Parser) duplicated_error(name string) IError {
	return p.error('`$name` is duplicated')
}
