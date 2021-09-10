// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.source { Pos }
import cotowali.errors { unreachable }

pub type Type = u64

pub struct UnknownTypeInfo {}

pub struct PrimitiveTypeInfo {}

pub struct PlaceholderTypeInfo {}

pub type TypeInfo = AliasTypeInfo
	| ArrayTypeInfo
	| FunctionTypeInfo
	| MapTypeInfo
	| PlaceholderTypeInfo
	| PrimitiveTypeInfo
	| ReferenceTypeInfo
	| StructTypeInfo
	| TupleTypeInfo
	| UnknownTypeInfo

pub struct TypeSymbol {
mut:
	scope &Scope = 0
pub mut:
	pos Pos
pub:
	typ  Type
	name string
	info TypeInfo = TypeInfo(PlaceholderTypeInfo{})
}

pub fn (v TypeSymbol) scope() ?&Scope {
	return Symbol(v).scope()
}

fn (v TypeSymbol) must_scope() &Scope {
	return v.scope() or { panic(unreachable('socpe not set')) }
}

fn (v TypeSymbol) scope_str() string {
	return Symbol(v).scope_str()
}

pub fn (v TypeSymbol) full_name() string {
	return Symbol(v).full_name()
}

pub enum TypeKind {
	placeholder
	unknown
	primitive
	function
	alias
	array
	map
	struct_
	reference
	tuple
}

// type kind
[inline]
pub fn (t TypeSymbol) kind() TypeKind {
	k := fn (k TypeKind) TypeKind {
		return k
	}
	return match t.info {
		UnknownTypeInfo { k(.unknown) }
		PlaceholderTypeInfo { k(.placeholder) }
		PrimitiveTypeInfo { k(.primitive) }
		FunctionTypeInfo { k(.function) }
		AliasTypeInfo { k(.alias) }
		ArrayTypeInfo { k(.array) }
		MapTypeInfo { k(.map) }
		StructTypeInfo { k(.struct_) }
		ReferenceTypeInfo { k(.reference) }
		TupleTypeInfo { k(.tuple) }
	}
}

pub fn (v TypeSymbol) str() string {
	return 'TypeSymbol{ typ: $v.typ, name: $v.name, kind: $v.kind().str() }'
}

// -- register / lookup --

fn (s &Scope) check_before_register_type(ts TypeSymbol) ? {
	if ts.typ != 0 && ts.typ in s.type_symbols {
		return error('$ts.typ is exists')
	}
	if ts.name.len > 0 && ts.name in s.name_to_type {
		return error('$ts.name is exists')
	}
}

pub fn (mut s Scope) register_type(ts TypeSymbol) ?&TypeSymbol {
	s.check_before_register_type(ts) ?
	typ := if ts.typ == 0 { Type(auto_id()) } else { ts.typ }
	new_ts := &TypeSymbol{
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
fn (mut s Scope) must_register_type(ts TypeSymbol) &TypeSymbol {
	return s.register_type(ts) or { panic(unreachable(err)) }
}

fn (mut s Scope) must_register_builtin_type(ts TypeSymbol) &TypeSymbol {
	s.check_before_register_type(ts) or { panic(err.msg) }
	new_ts := &TypeSymbol{
		...ts
	}
	s.type_symbols[ts.typ] = new_ts
	if ts.name.len > 0 && ts.kind() != .placeholder {
		s.name_to_type[new_ts.name] = new_ts.typ
	}
	return new_ts
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

pub fn (s &Scope) lookup_type(key TypeOrName) ?&TypeSymbol {
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

pub fn (s &Scope) must_lookup_type(key TypeOrName) &TypeSymbol {
	return s.lookup_type(key) or { panic(unreachable(err)) }
}

pub fn (mut s Scope) lookup_or_register_type(ts TypeSymbol) &TypeSymbol {
	if ts.name.len > 0 {
		return s.lookup_type(ts.name) or { s.must_register_type(ts) }
	}
	return s.lookup_type(ts.typ) or { s.must_register_type(ts) }
}
