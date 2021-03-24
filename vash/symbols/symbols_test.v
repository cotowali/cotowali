module symbols

fn test_var() {
	v := new_var('v')
	assert v.name == 'v'
	assert v.typ == unknown_type
}

fn test_type() {
	ts := new_type('t')
	assert ts.name == 't'
}
