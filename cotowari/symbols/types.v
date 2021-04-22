module symbols

import cotowari.util { auto_id }

pub struct Type {
	scope &Scope = 0
pub:
	id   u64
	name string
	info TypeInfo
}

pub fn (t Type) is_fn() bool {
	info := t.info
	return match info {
		PlaceholderTypeInfo { info.is_fn }
		else { false }
	}
}

pub struct UnknownTypeInfo {}

pub struct PrimitiveTypeInfo {}

pub struct PlaceholderTypeInfo {
	is_fn bool
}

pub type TypeInfo = PlaceholderTypeInfo | PrimitiveTypeInfo | UnknownTypeInfo

pub enum TypeKind {
	placeholder
	unknown
	primitive
}

// type kind
[inline]
fn tk(k TypeKind) TypeKind {
	return k
}

pub fn (t Type) kind() TypeKind {
	return match t.info {
		UnknownTypeInfo { tk(.unknown) }
		PlaceholderTypeInfo { tk(.placeholder) }
		PrimitiveTypeInfo { tk(.primitive) }
	}
}

pub fn new_type(name string, info TypeInfo) &Type {
	return &Type{
		id: auto_id()
		name: name
		info: info
	}
}

pub fn new_placeholder_type(name string) &Type {
	return new_type(name, PlaceholderTypeInfo{})
}

pub fn (v Type) full_name() string {
	return Symbol(v).full_name()
}

pub fn (v Type) scope() ?&Scope {
	return Symbol(v).scope()
}

pub fn (v Type) str() string {
	return "Type{ name: \'$v.name\', kind: $v.kind().str(), scope: ${Symbol(v).scope_str()} }"
}

pub const (
	unknown_type = Type{
		id: 1
		name: 'unknown'
		info: UnknownTypeInfo{}
	}
	int_type     = Type{
		id: 2
		name: 'int'
		info: PrimitiveTypeInfo{}
	}
	string_type  = Type{
		id: 3
		name: 'string'
		info: PrimitiveTypeInfo{}
	}
	bool_type    = Type{
		id: 4
		name: 'bool'
		info: PrimitiveTypeInfo{}
	}
)
