module symbols

import cotowari.util { auto_id }

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
		typ: new_type('placeholder', PlaceholderTypeInfo{})
		id: auto_id()
	}
}

pub fn new_fn(name string) &Var {
	return &Var{
		name: name
		typ: new_type('placeholder_fn', PlaceholderTypeInfo{ is_fn: true })
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
