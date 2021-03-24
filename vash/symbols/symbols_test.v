module symbols

fn test_var() {
	v := new_var('v')
	assert v.name == 'v'
	assert v.typ.kind == .placeholder
}

fn test_type() {
	ts := new_type('t', .placeholder)
	assert ts.name == 't'
	assert ts.kind == .placeholder
	assert new_placeholder_type().kind == .placeholder
}
