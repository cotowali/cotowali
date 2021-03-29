module symbols

fn test_var() ? {
	v := new_var('v')
	assert v.name == 'v'
	assert v.typ.kind() == .placeholder
	assert v.typ.is_fn() == false
	if _ := v.scope() {
		assert false
	}

	s := new_global_scope()
	v2 := new_scope_var('name', s)
	assert (v2.scope()?).id == s.id
}

fn test_new_fn() ?{
	f := new_fn('f')
	assert f.name == 'f'
	assert f.typ.kind() == .placeholder
	assert f.typ.is_fn()
	if _ := f.scope() {
		assert false
	}

	s := new_global_scope()
	v2 := new_scope_fn('name', s)
	assert (v2.scope()?).id == s.id
}

fn test_type() {
	ts := new_type('t', PlaceholderTypeInfo{})
	assert ts.name == 't'
	assert ts.kind() == .placeholder
	if _ := ts.scope() {
		assert false
	}
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

	v := new_var('v')
	t := new_type('t', PlaceholderTypeInfo{})
	assert v.full_name() == 'v'
	assert t.full_name() == 't'
	assert (global.register(v) ?).full_name() == 'v'
	assert (s.register(v) ?).full_name() == 's_v'
	assert (s_s.register(v) ?).full_name() == 's_s_v'
}
