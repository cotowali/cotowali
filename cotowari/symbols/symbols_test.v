module symbols

fn test_var() {
	v := new_var('v')
	assert v.name == 'v'
	assert v.typ.kind == .placeholder
}

fn test_type() {
	ts := new_type('t', .placeholder, PlaceholderTypeInfo{})
	assert ts.name == 't'
	assert ts.kind == .placeholder
}

fn test_full_name() ? {
	mut global := new_global_scope()
	mut s := global.create_child('s')
	mut s_s := s.create_child('s')

	v := new_var('v')
	t := new_type('t', .placeholder, PlaceholderTypeInfo{})
	assert v.full_name() == 'v'
	assert t.full_name() == 't'
	assert (global.register(v) ?).full_name() == 'v'
	assert (s.register(v) ?).full_name() == 's_v'
	assert (s_s.register(v) ?).full_name() == 's_s_v'
}
