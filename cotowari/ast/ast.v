module ast

import cotowari.symbols { Scope }
import cotowari.errors { Err }

pub struct File {
pub:
	path string
pub mut:
	stmts  []Stmt
	scope  &Scope
	errors []Err
}
