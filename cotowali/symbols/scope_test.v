// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

fn test_global_scope() {
	mut s := new_global_scope()
	assert s.is_global()
	s.must_lookup_type(builtin_type(.int))
	s.must_lookup_type(builtin_type(.void))
	s.must_lookup_type('string')
	assert s.must_lookup_var('echo').is_function()
	assert !s.create_child('s').is_global()
}

fn test_scope() ? {
	mut s := new_global_scope()
	if _ := s.parent() {
		assert false
	}
	mut child := s.create_child('child')
	assert (child.parent() ?).id == s.id
	assert s.children.len == 1
	assert s.children[0].id == child.id
}
