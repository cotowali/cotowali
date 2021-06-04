module symbols

import cotowari.util { auto_id }
import cotowari.source { Pos }
import cotowari.errors { unreachable }

pub type Type = u64

pub struct UnknownTypeInfo {}

pub struct PrimitiveTypeInfo {}

pub struct PlaceholderTypeInfo {
	is_function bool
}

pub type TypeInfo = ArrayTypeInfo | FunctionTypeInfo | PlaceholderTypeInfo | PrimitiveTypeInfo |
	UnknownTypeInfo

pub struct TypeSymbol {
mut:
	scope &Scope = 0
pub:
	pos  Pos
	typ  Type
	name string
	info TypeInfo = TypeInfo(PlaceholderTypeInfo{})
}

const unresolved_type_symbol = TypeSymbol{
	typ: Type(-1)
	name: 'unresolved'
	info: PlaceholderTypeInfo{}
}

pub fn (v TypeSymbol) scope() ?&Scope {
	return Symbol(v).scope()
}

fn (v TypeSymbol) scope_str() string {
	return Symbol(v).scope_str()
}

pub fn (v TypeSymbol) full_name() string {
	return Symbol(v).full_name()
}

pub fn (t TypeSymbol) is_function() bool {
	info := t.info
	return match info {
		PlaceholderTypeInfo { info.is_function }
		FunctionTypeInfo { true }
		else { false }
	}
}

pub enum TypeKind {
	placeholder
	unknown
	primitive
	func
	array
}

// type kind
[inline]
fn tk(k TypeKind) TypeKind {
	return k
}

pub fn (t TypeSymbol) kind() TypeKind {
	return match t.info {
		UnknownTypeInfo { tk(.unknown) }
		PlaceholderTypeInfo { tk(.placeholder) }
		PrimitiveTypeInfo { tk(.primitive) }
		FunctionTypeInfo { tk(.func) }
		ArrayTypeInfo { tk(.array) }
	}
}

pub fn (v TypeSymbol) str() string {
	return 'TypeSymbol{ typ: $v.typ, name: $v.name, kind: $v.kind().str() }'
}

// -- register / lookup --

fn (s &Scope) check_before_register_type(ts TypeSymbol) ? {
	if ts.typ in s.type_symbols {
		return error('$ts.typ is exists')
	}
	if ts.name.len > 0 && ts.name in s.name_to_type {
		return error('$ts.name is exists')
	}
}

pub fn (mut s Scope) register_type(ts TypeSymbol) ?TypeSymbol {
	s.check_before_register_type(ts) ?
	typ := if ts.typ == 0 { Type(auto_id()) } else { ts.typ }
	new_ts := TypeSymbol{
		...ts
		typ: typ
		scope: s
	}
	s.type_symbols[typ] = new_ts
	if new_ts.name.len > 0 {
		s.name_to_type[new_ts.name] = new_ts.typ
	}
	return new_ts
}

[inline]
fn (mut s Scope) must_register_type(ts TypeSymbol) TypeSymbol {
	return s.register_type(ts) or { panic(unreachable) }
}

type TypeOrName = Type | string

fn (s &Scope) name_to_type(name string) ?Type {
	if name in s.name_to_type {
		return s.name_to_type[name]
	} else if p := s.parent() {
		return p.name_to_type(name)
	} else {
		return error('unknown type `$name`')
	}
}

pub fn (s &Scope) lookup_type(key TypeOrName) ?TypeSymbol {
	// dont use `int_typ := if ...` to avoid compiler bug
	mut typ := u64(0)
	match key {
		string { typ = s.name_to_type(key) ? }
		Type { typ = key }
	}

	if typ in s.type_symbols {
		return s.type_symbols[typ]
	}

	if p := s.parent() {
		return p.lookup_type(key)
	}
	return none
}

pub fn (s &Scope) must_lookup_type(key TypeOrName) TypeSymbol {
	return s.lookup_type(key) or { panic(unreachable) }
}

pub fn (mut s Scope) lookup_or_register_type(ts TypeSymbol) TypeSymbol {
	if ts.name.len > 0 {
		return s.lookup_type(ts.name) or { s.must_register_type(ts) }
	}
	return s.lookup_type(ts.typ) or { s.must_register_type(ts) }
}
