module emit

import io
import cotowari.util { must_write }
import cotowari.ast { File }

pub struct Emitter {
mut:
	indent   int
	newline  bool = true
	cur_file File
pub:
	out io.Writer
}

[inline]
pub fn new_emitter(out io.Writer) Emitter {
	return Emitter{
		out: out
	}
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
	must_write(emit.out, s)
	emit.newline = s[s.len - 1] == `\n`
}

pub fn (mut emit Emitter) writeln(s string) {
	emit.write(s + '\n')
}

pub fn (mut emit Emitter) write_indent() {
	must_write(emit.out, '  '.repeat(emit.indent))
}
