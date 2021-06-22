module sh

import cotowari.ast
import cotowari.util { must_write }

pub fn (mut e Emitter) emit(f &ast.File) {
	e.file(f)
	for k in ordered_code_kinds {
		must_write(e.out, e.codes[k].bytes())
	}
}

fn (mut e Emitter) file(f &ast.File) {
	old_f := e.cur_file
	defer {
		e.cur_file = old_f
	}
	e.cur_file = f
	e.builtin()
	e.writeln('# file: $f.source.path')
	e.stmts(f.stmts)
}

fn (mut e Emitter) builtin() {
	builtins := [
		$embed_file('../../../builtin/builtin.sh'),
		$embed_file('../../../builtin/array.sh'),
	]
	old_kind := e.cur_kind
	defer {
		e.cur_kind = old_kind
	}
	e.cur_kind = .builtin
	for f in builtins {
		e.writeln(f.to_string())
	}
}
