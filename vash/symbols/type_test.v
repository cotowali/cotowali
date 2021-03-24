module symbols

fn test_type_symbol() {
	ts := new_type_symbol('t')
	assert ts.name == 't'
}
