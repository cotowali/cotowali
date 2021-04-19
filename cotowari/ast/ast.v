module ast

import cotowari.symbols { Scope }
import cotowari.errors { Err }
import cotowari.source { Source }

pub struct File {
pub:
	source Source
pub mut:
	stmts  []Stmt
	scope  &Scope
	errors []Err
}
