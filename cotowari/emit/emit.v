module emit

import cotowari.ast
import cotowari.token

pub fn (mut e Emitter) emit(f ast.File) {
	e.file(f)
}

fn (mut emit Emitter) file(f ast.File) {
	emit.cur_file = f
	emit.builtin()
	emit.writeln('# file: $f.source.path')
	emit.stmts(f.stmts)
}

fn (mut emit Emitter) builtin() {
	builtins := [
		$embed_file('../../builtin/builtin.sh'),
		$embed_file('../../builtin/array.sh'),
	]
	for f in builtins {
		emit.writeln(f.to_string())
	}
}
