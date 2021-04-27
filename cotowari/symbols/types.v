module symbols

pub type Type = int

/*
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
		FuncTypeInfo { true }
		else { false }
	}
}

pub struct UnknownTypeInfo {}

pub struct PrimitiveTypeInfo {}

pub struct PlaceholderTypeInfo {
	is_fn bool
}

pub struct FuncTypeInfo {
	args []Type
	ret  Type
}

pub type TypeInfo = FuncTypeInfo | PlaceholderTypeInfo | PrimitiveTypeInfo | UnknownTypeInfo

pub enum TypeKind {
	placeholder
	unknown
	primitive
	func
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
		FuncTypeInfo { tk(.func) }
	}
}

pub fn new_type(name string, info TypeInfo) Type {
	return Type{
		id: auto_id()
		name: name
		info: info
	}
}

pub fn new_placeholder_type(name string) Type {
	return new_type(name, PlaceholderTypeInfo{})
}

pub fn (v Type) full_name() string {
	return Symbol(v).full_name()
}

pub fn (v Type) scope() ?&Scope {
	return Symbol(v).scope()
}

pub fn (v Type) str() string {
	return 'Type{ name: \'$v.name\', kind: $v.kind().str(), scope: ${Symbol(v).scope_str()} }'
}
*/

