module parser

import cotowari.errors { Err }
import cotowari.source { Pos }

fn (mut p Parser) error(msg string, pos Pos) IError {
	p.trace(@FN, msg, '$pos')
	err := Err{
		source: p.file.source
		msg: msg
		pos: pos
	}
	p.file.errors << err
	p.consume()
	return err
}

fn (mut p Parser) duplicated_error(name string, pos Pos) IError {
	return p.error('`$name` is duplicated', pos)
}
