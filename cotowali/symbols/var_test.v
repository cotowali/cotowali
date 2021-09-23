// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.source { none_pos, pos }

fn test_lookup_and_register_var() ? {
	mut parent := new_global_scope()
	mut child := parent.must_create_child('child')

	name_v := 'v'

	parent_v := parent.register_var(name: name_v) ?
	mut found := parent.must_lookup_var(name_v)
	assert found.id == parent_v.id
	found = child.must_lookup_var(name_v)
	assert found.id == parent_v.id

	child_v := child.register_var(name: name_v) ?
	found = parent.must_lookup_var(name_v)
	assert found.id == parent_v.id
	assert found.id != child_v.id
	found = child.must_lookup_var(name_v)
	assert found.id != parent_v.id
	assert found.id == child_v.id

	if _ := child.register_var(name: name_v) {
		assert false
	}
	if _ := child.lookup_var('nothing') {
		assert false
	}
	if _ := child.lookup_var('nothing') {
		assert false
	}
}

fn test_lookup_var_with_pos() ? {
	mut parent := new_global_scope()
	mut child := parent.must_create_child('child')

	name_v := 'v'
	name_v_none := 'vnone'

	parent_v := parent.register_var(name: name_v, pos: pos(i: 1)) ?
	parent_v_none := parent.register_var(name: name_v_none, pos: none_pos()) ?

	assert parent.must_lookup_var_with_pos(name_v, none_pos()).id == parent_v.id
	assert parent.must_lookup_var_with_pos(name_v, pos(i: 1)).id == parent_v.id
	if _ := parent.lookup_var_with_pos(name_v, pos(i: 0)) {
		assert false
	}
	assert parent.must_lookup_var_with_pos(name_v_none, none_pos()).id == parent_v_none.id
	assert parent.must_lookup_var_with_pos(name_v_none, pos(i: 0)).id == parent_v_none.id

	assert child.must_lookup_var_with_pos(name_v, none_pos()).id == parent_v.id
	assert child.must_lookup_var_with_pos(name_v, pos(i: 1)).id == parent_v.id
	if _ := child.lookup_var_with_pos(name_v, pos(i: 0)) {
		assert false
	}
	assert child.must_lookup_var_with_pos(name_v_none, none_pos()).id == parent_v_none.id
	assert child.must_lookup_var_with_pos(name_v_none, pos(i: 0)).id == parent_v_none.id

	child_v := child.register_var(name: name_v, pos: pos(i: 2)) ?
	child_v_none := child.register_var(name: name_v_none, pos: none_pos()) ?

	assert child.must_lookup_var_with_pos(name_v, none_pos()).id == child_v.id
	assert child.must_lookup_var_with_pos(name_v, pos(i: 1)).id == parent_v.id
	assert child.must_lookup_var_with_pos(name_v, pos(i: 2)).id == child_v.id
	if _ := child.lookup_var_with_pos(name_v, pos(i: 0)) {
		assert false
	}
	assert child.must_lookup_var_with_pos(name_v_none, none_pos()).id == child_v_none.id
	assert child.must_lookup_var_with_pos(name_v_none, pos(i: 0)).id == child_v_none.id
	assert child.must_lookup_var_with_pos(name_v_none, pos(i: 1)).id == child_v_none.id
}

fn test_register_fn() ? {
	mut s := new_global_scope()
	f := s.register_fn(name: 'f', params: [builtin_type(.int)], ret: builtin_type(.void)) ?
	assert f.id != 0
	assert f.is_function()
}

fn test_lookup_or_register_var() ? {
	mut s := new_global_scope()
	v_n := s.vars.keys().len

	registered := s.lookup_or_register_var(name: 'v')
	assert registered.id != 0
	assert s.vars.keys().len == v_n + 1
	assert (registered.scope() ?).id == s.id

	found := s.lookup_or_register_var(name: 'v')
	assert registered.id == found.id
	assert s.vars.keys().len == v_n + 1
}

fn test_method() ? {
	mut s := new_global_scope()
	int_ := builtin_type(.int)

	t1 := (s.register_type(name: 'Type1') ?).typ
	t2 := (s.register_type(name: 'Type2') ?).typ

	if _ := s.lookup_method(t1, 'f') {
		assert false
	}

	method1 := s.register_method(name: 'f', receiver: t1, params: [int_], ret: int_) ?
	if _ := s.register_method(name: method1.name, receiver: t1, params: [int_], ret: int_) {
		assert false
	}
	assert method1.id != 0
	if found := s.lookup_method(t1, method1.name) {
		assert found.id == method1.id
	} else {
		assert false
	}

	// same name, different receiver
	method2 := s.register_method(name: 'f', receiver: t2, pipe_in: int_, params: [
		int_,
	]) ?
	assert method1.name == method2.name
	assert method2.id != 0
	assert method1.id != method2.id
	if found := s.lookup_method(t2, method2.name) {
		assert found.id == method2.id
	} else {
		assert false
	}

	assert (method2.type_symbol().fn_signature() ?) == 'fn (Type2) int | (int) void'
}
