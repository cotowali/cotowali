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

pub struct PlaceholderTypeInfo{
	is_fn bool
}

pub type TypeInfo = UnknownTypeInfo | PlaceholderTypeInfo

pub enum TypeKind {
	placeholder
	unknown
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
	}
}

pub fn new_type(name string, info TypeInfo) &Type {
	return &Type{
		id: auto_id()
		name: name
		info: info
	}
}

pub fn (v Type) full_name() string {
	return Symbol(v).full_name()
}

pub const (
	unknown_type = Type{
		id: 1
		name: 'unknown'
		info: UnknownTypeInfo{}
	}
)
