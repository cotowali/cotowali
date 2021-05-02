module symbols

fn test_global_scope() {
	mut s := new_global_scope()
	assert s.is_global()
	for t in builtin.types {
		if t != builtin_type(.placeholder) {
			s.must_lookup_type(t)
		}
	}
	for ts in builtin.type_symbols {
		s.must_lookup_type(ts.typ)
	}
	assert s.name_to_type.keys().len == builtin.type_symbols.len
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
