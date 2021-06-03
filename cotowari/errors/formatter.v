module errors

pub interface Formatter {
	format(Err) string
}

pub struct SimpleFormatter {}

pub fn (p SimpleFormatter) format(err Err) string {
	s := err.source
	pos := err.pos
	return '$s.file_name() $pos.line,$pos.col: $err.msg\n'
}

pub struct PrettyFormatter {}

pub fn (p PrettyFormatter) format(err Err) string {
	s := err.source
	pos := err.pos
	// TODO: More pretty
	code := s.slice(pos.i, pos.i + pos.len).clone()
	underline_len := utf8_str_visible_length(code)
	l1 := '$s.file_name() $pos.line,$pos.col: $err.msg'
	l2 := '  > ' + code
	l3 := '    ' + '^'.repeat(underline_len)
	return '$l1\n$l2\n$l3\n'
}
