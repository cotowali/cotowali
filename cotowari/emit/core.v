module emit

import io

pub struct Emitter {
mut:
	indent  int
	newline bool = true
pub:
	out io.Writer
}

[inline]
pub fn new(out io.Writer) Emitter {
	return Emitter{
		out: out
	}
}

pub fn (mut emit Emitter) raw_write(bytes []byte) {
	emit.out.write(bytes) or { panic(err) }
}

pub fn (mut emit Emitter) write(s string) {
	$if !prod {
		if s == '' {
			panic('writing empty')
		}
	}
	if emit.newline {
		emit.write_indent()
	}
	bytes := s.bytes()
	emit.raw_write(bytes)
	emit.newline = bytes.last() == `\n`
}

pub fn (mut emit Emitter) writeln(s string) {
	emit.write(s + '\n')
}

pub fn (mut emit Emitter) write_indent() {
	emit.raw_write('  '.repeat(emit.indent).bytes())
}
