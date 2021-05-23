module sh

import cotowari.ast
import cotowari.util { must_write }

pub fn (mut e Emitter) emit(f &ast.File) {
	e.file(f)
	must_write(e.out, e.code.bytes())
}

fn (mut e Emitter) file(f &ast.File) {
	e.cur_file = f
	e.builtin()
	e.code.writeln('# file: $f.source.path')
	e.stmts(f.stmts)
}

fn (mut e Emitter) builtin() {
	builtins := [
		$embed_file('../../../builtin/builtin.sh'),
		$embed_file('../../../builtin/array.sh'),
	]
	for f in builtins {
		e.code.writeln(f.to_string())
	}
}
