module symbols

fn test_var() ? {
	t := new_placeholder_type('t')
	v := new_var('v', t)
	assert v.name == 'v'
	assert v.typ.id == t.id
	assert v.typ.is_fn() == false
	if _ := v.scope() {
		assert false
	}

	v2 := new_placeholder_var('name', 't')
	assert v2.name == 'name'
	assert v2.typ.kind() == .placeholder

	s := new_global_scope()
	t3 := new_placeholder_type('t')
	v3 := new_scope_var('name', t3, s)
	assert v3.name == 'name'
	assert v3.typ.id == t3.id
	assert (v3.scope() ?).id == s.id

	v4 := new_scope_placeholder_var('name', 't', s)
	assert v4.name == 'name'
	assert (v4.scope() ?).id == s.id
	assert v4.typ.kind() == .placeholder
}

fn test_new_fn() ? {
	f := new_fn('f')
	assert f.name == 'f'
	assert f.typ.kind() == .placeholder
	assert f.typ.is_fn()
	if _ := f.scope() {
		assert false
	}

	s := new_global_scope()
	v2 := new_scope_fn('name', s)
	assert (v2.scope() ?).id == s.id
}

fn test_type() {
	ts := new_type('t', PlaceholderTypeInfo{})
	assert ts.name == 't'
	assert ts.kind() == .placeholder
	if _ := ts.scope() {
		assert false
	}

	pt := new_placeholder_type('t')
	assert pt.name == 't'
	assert pt.kind() == .placeholder
}

fn test_is_fn() {
	assert unknown_type.is_fn() == false
	assert new_type('t', PlaceholderTypeInfo{}).is_fn() == false
	assert new_type('t', PlaceholderTypeInfo{ is_fn: true }).is_fn()
}

fn test_full_name() ? {
	mut global := new_global_scope()
	mut s := global.create_child('s')
	mut s_s := s.create_child('s')

	v := new_placeholder_var('v', 't')
	t := new_type('t', PlaceholderTypeInfo{})
	assert v.full_name() == 'v'
	assert t.full_name() == 't'
	assert (global.register(v) ?).full_name() == 'v'
	assert (s.register(v) ?).full_name() == 's_v'
	assert (s_s.register(v) ?).full_name() == 's_s_v'
}
