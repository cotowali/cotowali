module scope

fn test_scope() ? {
	mut s := new_global_scope()
	if _ := s.parent() {
		assert false
	}
	child := s.create()
	//assert child.parent() ? == s
	assert s.children == [child]

	v1 := new_var('v1')

	if registered := s.register(v1) {
		if registered is Var {
			assert v1 == registered
		} else {
			assert false
		}
	}
	if _ := s.register(v1) {
		assert false
	}
}

fn test_var() {
	v := new_var('v')
	assert v.name == 'v'
	assert v.typ == unknown_type
}
