module symbols

fn test_global_scope() {
	mut s := new_global_scope()
	assert s.is_global()
	if t := s.lookup(unknown_type.name) {
		assert t.id == Symbol(unknown_type).id
	} else {
		assert false
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

	v1 := Symbol(new_var('v1'))

	if registered := s.register(v1) {
		assert v1.id == registered.id
		assert (registered.scope()?).id == s.id
	} else {
		assert false
	}
	if _ := s.register(v1) {
		assert false
	}

	if found := s.lookup(v1.name) {
		assert found.id == v1.id
	} else {
		assert false
	}
	if _ := child.lookup('nothing') {
		assert false
	}
}

fn test_ident_for() ? {
	mut global := new_global_scope()
	mut s := global.create_child('child')
	v := new_var('v')
	s.register(v) ?
	assert global.ident_for(v) == v.name
	assert s.ident_for(v).contains(s.id.str())
	assert s.ident_for(v).contains(v.name)
}

fn test_nested_scope() ? {
	mut parent := new_global_scope()
	mut child := parent.create_child('child')

	name := 'v'
	parent_v := Symbol(new_var(name))
	child_v := Symbol(new_var(name))
	assert parent_v.name == child_v.name
	assert parent_v.id != child_v.id

	parent.register(parent_v) ?
	if found := parent.lookup(name) {
		assert found.id == parent_v.id
		assert found.id != child_v.id
	} else {
		assert false
	}
	if found := child.lookup(name) {
		assert found.id == parent_v.id
		assert found.id != child_v.id
	} else {
		assert false
	}

	child.register(child_v) ?
	if found := parent.lookup(name) {
		assert found.id == parent_v.id
		assert found.id != child_v.id
	} else {
		assert false
	}
	if found := child.lookup(name) {
		assert found.id != parent_v.id
		assert found.id == child_v.id
	} else {
		assert false
	}

	if _ := child.lookup('nothing') {
		assert false
	}
}
