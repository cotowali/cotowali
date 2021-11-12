// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.util { nil_to_none }
import cotowali.messages { unreachable }
import cotowali.source { Pos }
import cotowali.token { TokenKind }

pub type ID = u64

[heap]
pub struct Scope {
pub:
	id   ID
	name string
pub mut:
	owner &Var = 0
	pos   Pos
mut:
	parent           &Scope = 0
	children         map[u64]&Scope // map[ID]&Scope
	name_to_child_id map[string]ID
	vars             map[string]&Var
	type_symbols     map[u64]&TypeSymbol     // map[Type]&TypeSymbol
	methods          map[u64]map[string]&Var // map[receiverType]map[name]&Var
	name_to_type     map[string]Type
	infix_op_fns     map[TokenKind]map[u64]map[u64]&Var // map[op TokenKind]map[lhs Type]map[rhs Type]&Var
}

pub fn (s &Scope) owner() ?&Var {
	if f := nil_to_none(s.owner) {
		return f
	}
	if p := s.parent() {
		return p.owner()
	}
	return none
}

pub fn (s &Scope) str() string {
	return s.full_name()
}

pub fn (s &Scope) debug_str() string {
	children_str := s.children().map(it.debug_str()).join('\n').split_into_lines().map('        $it').join('\n')
	vars_str := s.vars.keys().map("        '$it': ${s.vars[it]}").join('\n')
	types_str := s.type_symbols.keys().map('        ${s.type_symbols[it]}').join(',\n')
	return [
		'Scope{',
		'    id: $s.id',
		'    name: $s.name',
		'    children: [',
		children_str,
		'    ]',
		'    var: {',
		vars_str,
		'    }',
		'    types: [',
		types_str,
		'    ]',
		'}',
	].join('\n')
}

fn join_name(names ...string) string {
	return names.join('_')
}

pub const global_id = 1

pub fn new_global_scope() &Scope {
	mut s := &Scope{
		id: symbols.global_id
		parent: 0
	}
	s.register_builtin()
	return s
}

pub fn new_scope(name string, parent &Scope) &Scope {
	return &Scope{
		id: auto_id()
		name: name
		parent: parent
	}
}

pub fn (s &Scope) is_global() bool {
	return s.id == symbols.global_id
}

pub fn (s &Scope) full_name() string {
	name := if s.name.len > 0 { s.name } else { 'scope$s.id' }
	if p := s.parent() {
		if p.is_global() {
			return name
		}
		return join_name(p.full_name(), name)
	} else {
		return name
	}
}

[inline]
pub fn (s &Scope) parent() ?&Scope {
	return nil_to_none(s.parent)
}

pub fn (s &Scope) children() []&Scope {
	ids := s.children.keys()
	return ids.map(s.children[it])
}

pub fn (s &Scope) is_ancestor_of(target &Scope) bool {
	if s2 := target.parent() {
		return if s.id == s2.id { true } else { s.is_ancestor_of(s2) }
	}
	return false
}

type NameOrID = ID | string

pub fn (mut s Scope) get_child(key NameOrID) ?&Scope {
	match key {
		string {
			id := s.name_to_child_id[key] or { return none }
			return s.get_child(id)
		}
		ID {
			return s.children[key] or { return none }
		}
	}
}

pub fn (mut s Scope) create_child(name string) ?&Scope {
	child := new_scope(name, s)
	if name.len > 0 {
		if name in s.name_to_child_id {
			return error('$name is exists')
		}
		s.name_to_child_id[name] = child.id
	}
	s.children[child.id] = child
	return child
}

pub fn (mut s Scope) get_or_create_child(name string) &Scope {
	if found := s.get_child(name) {
		return found
	}
	return s.must_create_child(name)
}

pub fn (mut s Scope) must_create_child(name string) &Scope {
	return s.create_child(name) or { panic(unreachable(err.msg)) }
}

pub fn (s &Scope) ident_for(v Var) string {
	if s.id == symbols.global_id {
		return v.name
	}
	return 's${s.id}_$v.name'
}
