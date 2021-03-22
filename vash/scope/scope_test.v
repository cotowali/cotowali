module scope

fn test_scope() ? {
	mut s := new_global_scope()
	if _ := s.parent() {
		assert false
	}
	mut child := s.create()
	assert (child.parent() ?).id == s.id
	assert s.children == [child]

	v1 := new_var('v1')

	if registered := s.register(v1) {
		if registered is Var {
			assert v1 == registered
			assert v1.id != 0
		} else {
			assert false
		}
	}
	if _ := s.register(v1) {
		assert false
	}

	if found := child.lookup(v1.name) {
		if found is Var {
			assert found == v1
		}
	} else {
		assert false
	}

	child_v1 := new_var(v1.name)
	child.register(child_v1) ?
	if found := child.lookup(v1.name) {
		if found is Var {
			assert found != v1
			assert found == child_v1
		}
	} else {
		assert false
	}
	if found := s.lookup(v1.name) {
		if found is Var {
			assert found == v1
			assert found != child_v1
		}
	} else {
		assert false
	}
}

fn test_var() {
	v := new_var('v')
	assert v.name == 'v'
	assert v.typ == unknown_type
}
