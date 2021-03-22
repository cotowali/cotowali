module scope

fn test_scope() ? {
	mut s := new_global_scope()
	if _ := s.parent() {
		assert false
	}
	child := s.create()
	//assert child.parent() ? == s
	assert s.children == [child]

	var1 := new_var('v')
	s.register(var1) ?
	if _ := s.register(var1) {
		assert false
	}
}

fn test_var() {
	v := new_var('v')
	assert v.name == 'v'
	assert v.typ == unknown_type
}
