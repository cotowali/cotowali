module symbols

import cotowari.errors { unreachable }
import cotowari.util { auto_id }
import cotowari.source { Pos }

pub type Type = int

pub struct UnknownTypeInfo {}

pub struct PrimitiveTypeInfo {}

pub struct PlaceholderTypeInfo {
	is_function bool
}

pub struct FunctionTypeInfo {
	args []Type
	ret  Type = builtin_type(.void)
}

pub type TypeInfo = FunctionTypeInfo | PlaceholderTypeInfo | PrimitiveTypeInfo | UnknownTypeInfo

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
	}
}

pub fn (v TypeSymbol) str() string {
	return 'TypeSymbol{ typ: $v.typ, name: $v.name, kind: $v.kind().str() }'
}

fn (f FunctionTypeInfo) signature(s &Scope) string {
	args_str := f.args.map(s.must_lookup_type(it).name).join(', ')
	return 'fn ($args_str) ${s.must_lookup_type(f.ret).name}'
}

pub fn (t TypeSymbol) fn_signature() ?string {
	return if t.info is FunctionTypeInfo {
		t.info.signature(t.scope() or { panic(unreachable) })
	} else {
		none
	}
}

// -- register / lookup --

fn (s &Scope) check_before_register_type(ts TypeSymbol) ? {
	if int(ts.typ) in s.type_symbols {
		return error('$ts.typ is exists')
	}
	if ts.name.len > 0 && ts.name in s.name_to_type {
		return error('$ts.name is exists')
	}
}

pub fn (mut s Scope) register_type(ts TypeSymbol) ?TypeSymbol {
	s.check_before_register_type(ts) ?
	typ := if ts.typ == 0 { Type(int(auto_id())) } else { ts.typ }
	new_ts := TypeSymbol{
		...ts
		typ: typ
		scope: s
	}
	s.type_symbols[int(typ)] = new_ts
	if new_ts.name.len > 0 {
		s.name_to_type[new_ts.name] = new_ts.typ
	}
	return new_ts
}

[inline]
fn (mut s Scope) must_register_type(ts TypeSymbol) TypeSymbol {
	return s.register_type(ts) or { panic(err) }
}

type TypeOrName = Type | string

// pub fn (s &Scope) lookup_type(key Type | string) ?TypeSymbol {
pub fn (s &Scope) lookup_type(key TypeOrName) ?TypeSymbol {
	// dont use `int_typ := if ...` to avoid compiler bug
	mut int_typ := 0
	if key is string {
		if key in s.name_to_type {
			int_typ = s.name_to_type[key]
		} else if p := s.parent() {
			return p.lookup_type(key)
		} else {
			return error('unknown type `$key`')
		}
	} else {
		int_typ = int(key as Type)
	}

	if int_typ in s.type_symbols {
		return s.type_symbols[int_typ]
	}
	if p := s.parent() {
		return p.lookup_type(key)
	}
	return none
}

pub fn (s &Scope) must_lookup_type(key TypeOrName) TypeSymbol {
	return s.lookup_type(key) or { panic(err) }
}

pub fn (mut s Scope) lookup_or_register_type(ts TypeSymbol) TypeSymbol {
	if ts.name.len > 0 {
		return s.lookup_type(ts.name) or { s.register_type(ts) or { panic(err) } }
	}
	return s.lookup_type(ts.typ) or { s.register_type(ts) or { panic(err) } }
}

pub fn (mut s Scope) lookup_or_register_fn_type(args []Type, ret Type) TypeSymbol {
	info := FunctionTypeInfo{args, ret}
	typename := info.signature(s)
	return s.lookup_or_register_type(name: typename, info: info)
}
