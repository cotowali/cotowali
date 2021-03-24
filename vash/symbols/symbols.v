module symbols

import vash.util { auto_id }

pub type ScopeObject = TypeSymbol | Var

pub struct Var {
pub:
	name string
	id   u64
pub mut:
	typ TypeSymbol
}

pub fn new_var(name string) Var {
	return Var{
		name: name
		typ: unknown_type
		id: auto_id()
	}
}

pub struct TypeSymbol {
pub mut:
	id u64
pub:
	name string
}

pub fn new_type_symbol(name string) TypeSymbol {
	return TypeSymbol{
		id: auto_id()
		name: name
	}
}

pub const (
	unknown_type = TypeSymbol{
		id: 1
		name: 'unknown'
	}
)
