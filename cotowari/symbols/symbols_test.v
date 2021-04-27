module symbols

fn test_var() ? {
	t := new_placeholder_type('t')
	v := new_var('v', t)
	assert v.name == 'v'
	assert v.typ == t
	if _ := v.scope() {
		assert false
	}

	v2 := new_placeholder_var('name', 't')
	assert v2.name == 'name'

	s := new_global_scope()
	t3 := new_placeholder_type('t')
	v3 := new_scope_var('name', t3, s)
	assert v3.name == 'name'
	assert v3.typ == t3
	assert (v3.scope() ?).id == s.id

	v4 := new_scope_placeholder_var('name', 't', s)
	assert v4.name == 'name'
	assert (v4.scope() ?).id == s.id
}

fn test_new_fn() ? {
	f := new_fn('f', [], builtin_type(.unknown))
	assert f.name == 'f'
	if _ := f.scope() {
		assert false
	}

	s := new_global_scope()
	v2 := new_scope_fn('f', [], builtin_type(.unknown), s)
	assert (v2.scope() ?).id == s.id
}

fn test_full_name() ? {
	mut global := new_global_scope()
	mut s := global.create_child('s')
	mut s_s := s.create_child('s')

	v := new_placeholder_var('v', 't')
	assert v.full_name() == 'v'
	assert (global.register(v) ?).full_name() == 'v'
	assert (s.register(v) ?).full_name() == 's_v'
	assert (s_s.register(v) ?).full_name() == 's_s_v'
}
