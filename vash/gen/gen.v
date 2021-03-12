module gen

import io
import vash.ast

pub struct Gen {
pub:
	out io.Writer
}

[inline]
pub fn new(out io.Writer) Gen {
	return Gen{
		out: out
	}
}

pub fn (mut g Gen) write(s string) {
	g.out.write(s.bytes()) or { panic(err) }
}

pub fn (mut g Gen) writeln(s string) {
	g.write(s + '\n')
}

pub fn (mut g Gen) gen(f ast.File) {
	g.file(f)
}

fn (mut g Gen) file(f ast.File) {
	g.writeln('# file: $f.path')
}
