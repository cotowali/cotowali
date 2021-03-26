module symbols

import vash.util { auto_id }

pub type Symbol = Type | Var

pub fn (sym Symbol) scope() ?&Scope {
	if isnil(sym.scope) {
		return none
	}
	return sym.scope
}

pub fn (sym Symbol) full_name() string {
	name := if sym.name.len > 0 { sym.name } else { 'sym$sym.id' }
	if s := sym.scope() {
		if s.is_global() {
			return name
		}
		return join_name(s.full_name(), name)
	} else {
		return name
	}
}

pub struct Var {
	scope &Scope = 0
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

pub fn (v Var) full_name() string {
	return Symbol(v).full_name()
}

pub struct Type {
	scope &Scope = 0
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

pub fn (v Type) full_name() string {
	return Symbol(v).full_name()
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
