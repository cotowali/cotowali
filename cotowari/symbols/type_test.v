module symbols

fn test_fn_signature() ? {
	mut s := new_global_scope()
	f1 := s.register_type(
		name: 'f1'
		info: FunctionTypeInfo{
			params: [builtin_type(.int), builtin_type(.bool)]
		}
	) ?
	f2 := s.register_type(
		name: 'f2'
		info: FunctionTypeInfo{
			params: [builtin_type(.int), builtin_type(.bool)]
			ret: builtin_type(.int)
		}
	) ?
	assert f1.fn_signature() ? == 'fn (int, bool) void'
	assert f2.fn_signature() ? == 'fn (int, bool) int'
	if _ := s.must_lookup_type(builtin_type(.int)).fn_signature() {
		assert false
	}
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
	assert (registered.scope() ?).id == s.id
	assert registered.typ != Type(0)
	assert s.type_symbols.keys().len == ts_n + 1

	mut found := s.lookup_or_register_type(typ: registered.typ)
	assert registered.typ == found.typ
	assert s.type_symbols.keys().len == ts_n + 1

	found = s.lookup_or_register_type(name: registered.name)
	assert registered.typ == found.typ
	assert s.type_symbols.keys().len == ts_n + 1
}
