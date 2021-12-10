// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.source { Pos }
import cotowali.messages { already_defined }
import cotowali.util { li_panic, nil_to_none }

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
	| SequenceTypeInfo
	| StructTypeInfo
	| TupleTypeInfo
	| UnknownTypeInfo

pub struct TypeSymbol {
mut:
	scope   &Scope = 0
	methods map[string]&Var
pub mut:
	pos Pos
pub:
	base &TypeSymbol = 0
	typ  Type
	name string
	info TypeInfo = TypeInfo(PlaceholderTypeInfo{})
}

pub fn (v TypeSymbol) scope() ?&Scope {
	return Symbol(v).scope()
}

fn (v TypeSymbol) must_scope() &Scope {
	return v.scope() or { li_panic(@FILE, @LINE, 'socpe not set') }
}

fn (v TypeSymbol) scope_str() string {
	return Symbol(v).scope_str()
}

pub fn (v TypeSymbol) name_for_ident() string {
	return Symbol(v).name_for_ident()
}

pub fn (v TypeSymbol) display_name() string {
	return Symbol(v).display_name()
}

pub fn (ts &TypeSymbol) base() ?&TypeSymbol {
	return nil_to_none(ts.base)
}

pub enum TypeKind {
	placeholder
	unknown
	primitive
	function
	alias
	array
	map
	sequence
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
		SequenceTypeInfo { k(.sequence) }
		StructTypeInfo { k(.struct_) }
		ReferenceTypeInfo { k(.reference) }
		TupleTypeInfo { k(.tuple) }
	}
}

pub fn (t TypeSymbol) is_iterable() bool {
	return t.resolved().kind() in [.array, .sequence]
}

pub fn (v TypeSymbol) str() string {
	return 'TypeSymbol{ typ: $v.typ, name: $v.name, kind: $v.kind().str() }'
}

// -- register / lookup --

fn (s &Scope) check_before_register_type(ts TypeSymbol) ? {
	if ts.typ != 0 && ts.typ in s.type_symbols {
		li_panic(@FILE, @LINE, '$ts.typ is exists')
	}
	if ts.name.len > 0 && ts.name in s.name_to_type {
		return error(already_defined(.typ, ts.name))
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
	s.root().type_symbols[typ] = new_ts
	if new_ts.name.len > 0 {
		s.name_to_type[new_ts.name] = new_ts.typ
	}
	return new_ts
}

[inline]
fn (mut s Scope) must_register_type(ts TypeSymbol) &TypeSymbol {
	return s.register_type(ts) or { li_panic(@FILE, @LINE, err) }
}

fn (mut s Scope) must_register_builtin_type(ts TypeSymbol) &TypeSymbol {
	s.check_before_register_type(ts) or { li_panic(@FILE, @LINE, err) }
	new_ts := &TypeSymbol{
		...ts
		scope: s
	}
	s.root().type_symbols[ts.typ] = new_ts
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

	root := s.root()

	return root.type_symbols[typ] or { return none }
}

pub fn (s &Scope) must_lookup_type(key TypeOrName) &TypeSymbol {
	return s.lookup_type(key) or { li_panic(@FILE, @LINE, err) }
}

pub fn (mut s Scope) lookup_or_register_type(ts TypeSymbol) &TypeSymbol {
	if ts.name.len > 0 {
		return s.lookup_type(ts.name) or { s.must_register_type(ts) }
	}
	return s.lookup_type(ts.typ) or { s.must_register_type(ts) }
}

// -- methods --

pub fn (mut ts TypeSymbol) register_method(f RegisterFnArgs) ?&Var {
	fn_typ := ts.scope.lookup_or_register_function_type(FunctionTypeInfo{
		...f.FunctionTypeInfo
		receiver: ts.typ
	}).typ

	name := f.Var.name
	v := &Var{
		...f.Var
		name: ts.name + '.' + name
		id: if f.Var.id == 0 { auto_id() } else { f.Var.id }
		typ: fn_typ
		receiver_typ: ts.typ
		scope: ts.must_scope()
	}
	if name == '' {
		li_panic(@FILE, @LINE, 'method name is empty')
	}
	if name in ts.methods {
		return error(already_defined(.method, '$v.name'))
	}
	ts.methods[name] = v

	return v
}

pub fn (ts &TypeSymbol) lookup_method(name string) ?&Var {
	return ts.methods[name] or {
		if base := ts.base() {
			if found := base.lookup_method(name) {
				return found
			}
		}
		if alias_info := ts.alias_info() {
			return ts.scope.must_lookup_type(alias_info.target).lookup_method(name)
		}
		return none
	}
}
