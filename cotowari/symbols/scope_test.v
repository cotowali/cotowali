module symbols

fn test_global_scope() {
	mut s := new_global_scope()
	assert s.is_global()
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

	name := 'v'
	if registered := s.register(name: name) {
		assert registered.id != 0
		assert (registered.scope() ?).id == s.id
	} else {
		assert false
	}

	// duplicate
	if _ := s.register(name: name) {
		assert false
	}

	found := s.must_lookup(name)
	assert found.id != 0

	if _ := child.lookup('nothing') {
		assert false
	}
}

fn test_lookup() ? {
	mut parent := new_global_scope()
	mut child := parent.create_child('child')

	name_v := 'v'

	parent_v := parent.register(name: name_v) ?
	mut found := parent.must_lookup(name_v)
	assert found.id == parent_v.id
	found = child.must_lookup(name_v)
	assert found.id == parent_v.id

	child_v := child.register(name: name_v) ?
	found = parent.must_lookup(name_v)
	assert found.id == parent_v.id
	assert found.id != child_v.id
	found = child.must_lookup(name_v)
	assert found.id != parent_v.id
	assert found.id == child_v.id

	if _ := child.lookup('nothing') {
		assert false
	}
	if _ := child.lookup_var('nothing') {
		assert false
	}
}

fn test_lookup_or_register() ? {
	mut s := new_global_scope()
	assert s.symbols.keys().len == 0
	registered := s.lookup_or_register_var(name: 'v')
	assert registered.id != 0
	assert s.symbols.keys().len == 1
	assert (registered.scope() ?).id == s.id

	found := s.lookup_or_register_var(name: 'v')
	assert registered.id == found.id
	assert s.symbols.keys().len == 1
}
