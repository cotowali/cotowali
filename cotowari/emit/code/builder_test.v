module code

import cotowari.context { new_context }

fn test_builder_simple() ? {
	mut b := new_builder(10, new_context(indent: ' '))
	s1, s2, s3 := 'bytes', 'str', 'strln'
	mut n := 0
	n = b.write(s1.bytes()) ?
	assert n == s1.len
	n = b.write_string(s2) ?
	assert n == s2.len
	n = b.writeln(s3) ?
	assert n == s3.len + 1

	s := s1 + s2 + s3 + '\n'
	assert b.len() == s.len
	assert b.bytes() == s.bytes()
	assert b.str() == s

	assert b.len() == 0
}

fn test_builder_indent() ? {
	indent := '  '
	mut b := new_builder(10, new_context(indent: indent))
	s0_0, s0_1 := '0abc', '0efg'
	s1_0, s1_1 := '1abc', '1efg'
	s2_0, s2_1 := '2abc', '2efg'
	s3_0, s3_1 := '3abc', '3efg'
	s4_0, s4_1 := '4abc', '4efg'

	// -- normal usage

	b.write_string(s0_0) ?
	b.write_string(s0_1) ?
	b.writeln('') ?
	b.indent()

	b.write_string(s1_0) ?
	b.write_string(s1_1) ?
	b.writeln('') ?
	b.indent()

	b.write_string(s2_0) ?
	b.write_string(s2_1) ?
	b.writeln('') ?
	b.unindent()

	b.write_string(s3_0) ?
	b.write_string(s3_1) ?
	b.writeln('') ?
	b.unindent()

	b.write_string(s4_0) ?
	b.write_string(s4_1) ?
	b.writeln('') ?

	out1 := b.str()

	assert out1 == [
		'$s0_0' + '$s0_1' + '\n',
		indent + '$s1_0' + '$s1_1' + '\n',
		indent + indent + '$s2_0' + '$s2_1' + '\n',
		indent + '$s3_0' + '$s3_1' + '\n',
		'$s4_0' + '$s4_1' + '\n',
	].join('')

	// -- indent only after newline

	b.write_string(s0_0) ?
	b.indent()
	b.write_string(s0_1) ?
	b.writeln('') ?

	b.write_string(s1_0) ?
	b.indent()
	b.write_string(s1_1) ?
	b.writeln('') ?

	b.write_string(s2_0) ?
	b.unindent()
	b.write_string(s2_1) ?
	b.writeln('') ?

	b.write_string(s3_0) ?
	b.unindent()
	b.write_string(s3_1) ?
	b.writeln('') ?

	b.write_string(s4_0) ?
	b.indent()
	b.write_string(s4_1) ?
	b.writeln('') ?

	assert b.str() == out1
}
