module scope

fn test_scope() ? {
	mut s := new_global_scope()
	if _ := s.parent() {
		assert false
	}
	child := s.create()
	assert child.parent() ? == s
	assert s.children == [child]
}
