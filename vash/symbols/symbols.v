module symbols

import vash.util { auto_id }

pub type Symbol = Type | Var

pub struct Var {
pub:
	name string
	id   u64
pub mut:
	typ &Type
}

pub fn new_var(name string) &Var {
	return &Var{
		name: name
		typ: &symbols.unknown_type
		id: auto_id()
	}
}

pub struct Type {
pub:
	id   u64
	name string
	info TypeInfo
}

pub struct NoTypeInfo {}

pub type TypeInfo = NoTypeInfo

pub fn new_type(name string) &Type {
	return &Type{
		id: auto_id()
		name: name
		info: NoTypeInfo{}
	}
}

pub const (
	unknown_type = Type{
		id: 1
		name: 'unknown'
	}
)
