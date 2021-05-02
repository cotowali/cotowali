module symbols

fn test_lookup_and_register() ? {
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

	if _ := child.register(name: name_v) {
		assert false
	}
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

fn test_lookup_type_and_register_type() ? {
	mut parent := new_global_scope()
	mut child := parent.create_child('child')

	name_t := 't'

	parent_t := parent.register_type(name: 't') ?
	mut found := parent.must_lookup_type(parent_t.typ)
	assert found.typ == parent_t.typ
	found = parent.must_lookup_type(parent_t.name)
	assert found.typ == parent_t.typ
	found = child.must_lookup_type(parent_t.typ)
	assert found.typ == parent_t.typ
	found = child.must_lookup_type(parent_t.name)
	assert found.typ == parent_t.typ

	child_t := child.register_type(name: 't') ?
	if _ := parent.lookup_type(child_t.typ) {
		assert false
	}
	found = child.must_lookup_type(child_t.typ)
	assert found.typ != parent_t.typ
	assert found.typ == child_t.typ
	found = child.must_lookup_type(child_t.name)
	assert found.typ != parent_t.typ
	assert found.typ == child_t.typ

	if _ := child.lookup_type(Type(99999)) {
		assert false
	}
	if _ := child.register_type(typ: child_t.typ) {
		assert false
	}
	if _ := child.register_type(name: child_t.name) {
		assert false
	}
}

fn test_lookup_or_register_type() ? {
	mut s := new_global_scope()
	ts_n := s.type_symbols.keys().len
	registered := s.lookup_or_register_type(name: 't')
	assert registered.typ != Type(0)
	assert s.type_symbols.keys().len == ts_n + 1

	mut found := s.lookup_or_register_type(typ: registered.typ)
	assert registered.typ == found.typ
	assert s.type_symbols.keys().len == ts_n + 1

	found = s.lookup_or_register_type(name: registered.name)
	assert registered.typ == found.typ
	assert s.type_symbols.keys().len == ts_n + 1
}
