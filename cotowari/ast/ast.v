module ast

import cotowari.errors { Err }
import cotowari.source { Source }

[heap]
pub struct File {
pub:
	source &Source
pub mut:
	stmts  []Stmt
	errors []Err

	has_syntax_error bool
}
