// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.source { Pos, new_source, none_pos }
import cotowali.messages { already_defined }
import cotowali.util { li_panic }

pub struct Var {
mut:
	scope &Scope = unsafe { 0 }
pub:
	name           string
	id             u64
	pos            Pos = none_pos()
	is_placeholder bool
	is_const       bool
pub mut:
	mangle       bool
	typ          Type = builtin_type(.placeholder)
	receiver_typ Type = builtin_type(.placeholder)
}

pub fn (v Var) is_member() bool {
	return v.receiver_typ != builtin_type(.placeholder)
}

pub fn (v Var) is_function() bool {
	return v.type_symbol().kind() == .function
}

pub fn (v Var) is_method() bool {
	return v.is_function() && v.is_member()
}

pub fn (v Var) str() string {
	return 'Var{ id: ${v.id}, name: ${v.name}, scope: ${v.scope_str()}, typ: ${v.typ} }'
}

pub fn (v Var) scope() ?&Scope {
	return Symbol(v).scope()
}

fn (v Var) scope_str() string {
	return Symbol(v).scope_str()
}

pub fn (v Var) name_for_ident() string {
	return Symbol(v).name_for_ident()
}

pub fn (v Var) display_name() string {
	return Symbol(v).display_name()
}

pub fn (v Var) type_symbol() &TypeSymbol {
	if scope := v.scope() {
		return scope.lookup_type(v.typ) or { unresolved_type_symbol }
	}
	return unresolved_type_symbol
}

pub fn (v Var) receiver_type_symbol() &TypeSymbol {
	if scope := v.scope() {
		return scope.lookup_type(v.receiver_typ) or { unresolved_type_symbol }
	}
	return unresolved_type_symbol
}

// -- lookup / register --

fn (mut s Scope) check_before_register_var(v Var) ! {
	key := v.name
	found_v := s.vars[key] or { return }

	msg := if found_v.is_function() {
		already_defined(.function, key)
	} else {
		already_defined(.variable, key)
	}
	return error(msg)
}

pub fn (mut s Scope) register_var(v Var) !&Var {
	s.check_before_register_var(v)!
	new_v := &Var{
		...v
		id: if v.id == 0 { auto_id() } else { v.id }
		scope: s
	}
	s.vars[new_v.name] = new_v
	return new_v
}

pub fn new_placeholder_var(name string, pos Pos) &Var {
	return &Var{
		name: name
		typ: builtin_type(.placeholder)
		is_placeholder: true
		pos: pos
	}
}

pub fn (mut s Scope) must_register_var(v Var) &Var {
	return s.register_var(v) or { li_panic(@FN, @FILE, @LINE, err) }
}

pub fn (s &Scope) lookup_var(name string) ?&Var {
	if name == '_' {
		return none
	}
	return s.vars[name] or {
		p := s.parent()?
		p.lookup_var(name)?
	}
}

pub fn (s &Scope) must_lookup_var(name string) &Var {
	return s.lookup_var(name) or { li_panic(@FN, @FILE, @LINE, err) }
}

pub fn (s &Scope) lookup_var_with_pos(name string, pos Pos) ?&Var {
	v := s.vars[name] or {
		p := s.parent()?
		return p.lookup_var_with_pos(name, pos)
	}
	s1 := v.pos.source() or { new_source('', '') }
	s2 := pos.source() or { new_source('', '') }
	return if v.pos.i <= pos.i || s1 != s2 || v.pos.is_none() || pos.is_none() {
		v
	} else {
		none
	}
}

pub fn (s &Scope) must_lookup_var_with_pos(name string, pos Pos) &Var {
	return s.lookup_var_with_pos(name, pos) or { li_panic(@FN, @FILE, @LINE, err) }
}

pub fn (mut s Scope) lookup_or_register_var(v Var) &Var {
	return s.lookup_var(v.name) or { s.register_var(v) or { li_panic(@FN, @FILE, @LINE, err) } }
}
