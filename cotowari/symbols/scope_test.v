module symbols

fn test_global_scope() {
	mut s := new_global_scope()
	assert s.is_global()
	builtins := [unknown_type, int_type, string_type, bool_type]
	for t in builtins {
		found := s.must_lookup(t.name)
		assert found.id == t.id
		assert found.name == t.name
	}
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

	t1 := new_type('t1', PlaceholderTypeInfo{})
	v1 := new_var('v1', t1)

	if registered := s.register(v1) {
		assert v1.id == registered.id
		assert (registered.scope() ?).id == s.id
		assert registered is Var
	} else {
		assert false
	}

	if registered := s.register(t1) {
		assert t1.id == registered.id
		assert (registered.scope() ?).id == s.id
		assert registered is Type
	} else {
		assert false
	}
	if _ := s.register(v1) {
		assert false
	}

	found := s.must_lookup(v1.name)
	assert found.id == v1.id

	if _ := child.lookup('nothing') {
		assert false
	}
}

fn test_lookup() ? {
	mut parent := new_global_scope()
	mut child := parent.create_child('child')

	name_v := 'v'
	parent_v := new_placeholder_var(name_v, 't')
	child_v := new_placeholder_var(name_v, 't')
	assert parent_v.name == child_v.name
	assert parent_v.id != child_v.id

	parent.register(parent_v) ?
	if found := parent.lookup(name_v) {
		assert found.id == parent_v.id
		assert found.id != child_v.id
		assert found is Var
	} else {
		assert false
	}
	if found := child.lookup(name_v) {
		assert found.id == parent_v.id
		assert found.id != child_v.id
		assert found is Var
	} else {
		assert false
	}

	child.register(child_v) ?
	mut found := parent.must_lookup(name_v)
	assert found.id == parent_v.id
	assert found.id != child_v.id
	assert found is Var
	found = child.must_lookup(name_v)
	assert found.id != parent_v.id
	assert found.id == child_v.id
	assert found is Var

	if _ := child.lookup('nothing') {
		assert false
	}
	if _ := child.lookup_var('nothing') {
		assert false
	}
	if _ := child.lookup_type('nothing') {
		assert false
	}

	t := new_type('t', PlaceholderTypeInfo{})
	parent.register(t) ?
	found_v := parent.must_lookup_var(name_v)
	assert found_v.name == name_v
	found_t := parent.must_lookup_type(t.name)
	assert found_t.name == t.name

	if _ := parent.lookup_var(t.name) {
		assert false
	}
	if _ := parent.lookup_type(name_v) {
		assert false
	}
}
