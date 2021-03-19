module gen

import io
import vash.ast { Pipeline, Stmt }

pub struct Gen {
mut:
	indent  int
	newline bool = true
pub:
	out io.Writer
}

[inline]
pub fn new(out io.Writer) Gen {
	return Gen{
		out: out
	}
}

pub fn (mut g Gen) raw_write(bytes []byte) {
	g.out.write(bytes) or { panic(err) }
}

pub fn (mut g Gen) write(s string) {
	$if !prod {
		if s == '' {
			panic('writing empty')
		}
	}
	if g.newline {
		g.write_indent()
	}
	bytes := s.bytes()
	g.raw_write(bytes)
	g.newline = bytes.last() == `\n`
}

pub fn (mut g Gen) writeln(s string) {
	g.write(s + '\n')
}

pub fn (mut g Gen) write_indent() {
	g.raw_write('  '.repeat(g.indent).bytes())
}
