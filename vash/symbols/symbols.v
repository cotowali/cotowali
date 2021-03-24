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
		typ: new_placeholder_type()
		id: auto_id()
	}
}

pub struct Type {
pub:
	id   u64
	name string
	kind TypeKind
	info TypeInfo
}

pub enum TypeKind {
	placeholder
	unknown
}

pub struct NoTypeInfo {}

pub type TypeInfo = NoTypeInfo

pub fn new_type(name string, kind TypeKind) &Type {
	return &Type{
		id: auto_id()
		name: name
		kind: kind
		info: NoTypeInfo{}
	}
}

pub fn new_placeholder_type() &Type {
	return new_type('unresolved', .placeholder)
}

pub const (
	unknown_type = Type{
		id: 1
		name: 'unknown'
		kind: .unknown
	}
)
