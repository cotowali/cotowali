module symbols

fn test_lookup_and_register_var() ? {
	mut parent := new_global_scope()
	mut child := parent.create_child('child')

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

fn test_register_fn() ? {
	mut s := new_global_scope()
	f := s.register_fn('f', args: [builtin_type(.int)], ret: builtin_type(.void)) ?
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
