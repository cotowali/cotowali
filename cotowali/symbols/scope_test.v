// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.source { pos }

fn test_global_scope() {
	mut s := new_global_scope()
	assert s.is_global()
	s.must_lookup_type(builtin_type(.int))
	s.must_lookup_type(builtin_type(.void))
	s.must_lookup_type('string')
	assert s.must_lookup_var('echo').is_function()
	assert !s.must_create_child('s').is_global()
}

fn test_scope() ? {
	mut s := new_global_scope()
	if _ := s.parent() {
		assert false
	}

	mut child := s.must_create_child('child')
	assert (child.parent()?).id == s.id
	assert s.children().len == 1
	assert s.children()[0].id == child.id
	if _ := s.create_child('child') {
		assert false
	} else {
		assert true
	}

	assert (s.get_child(child.name)?).id == child.id
	if _ := s.get_child('none') {
		assert false
	} else {
		assert true
	}

	assert s.children().len == 1
	assert s.get_or_create_child(child.name).id == child.id
	assert s.children().len == 1
	assert s.get_or_create_child('new').name == 'new'
	assert s.children().len == 2

	mut child2 := s.must_create_child('child2')
	child_child := child.must_create_child('child')
	child2_child := child2.must_create_child('child2')
	assert s.is_ancestor_of(child)
	assert s.is_ancestor_of(child2)
	assert s.is_ancestor_of(child_child)
	assert s.is_ancestor_of(child2_child)
	assert child.is_ancestor_of(child_child)
	assert child2.is_ancestor_of(child2_child)
	assert !child.is_ancestor_of(child2_child)
	assert !child2.is_ancestor_of(child_child)
	assert !s.is_ancestor_of(s)
}

fn test_innermost() {
	mut s := new_global_scope()
	s.pos = pos(line: 1, last_line: 10)
	mut s_1 := s.must_create_child('1')
	s_1.pos = pos(line: 3, last_line: 6)
	mut s_1_1 := s_1.must_create_child('1')
	s_1_1.pos = pos(line: 5, last_line: 5, col: 1, len: 3)
	mut s_1_2 := s_1.must_create_child('2')
	s_1_2.pos = pos(line: 5, last_line: 5, col: 6, len: 3)
	mut s_2 := s.must_create_child('2')
	s_2.pos = pos(line: 7, last_line: 9)

	println(s_1.id)
	println(s_1_1.id)
	assert s.innermost(line: 2).id == s.id
	assert s.innermost(line: 4).id == s_1.id
	assert s.innermost(line: 5, col: 2).id == s_1_1.id
	assert s.innermost(line: 5, col: 8).id == s_1_2.id
	assert s.innermost(line: 8).id == s_2.id
}
