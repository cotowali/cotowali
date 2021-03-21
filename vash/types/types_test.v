module types

fn test_symbol() {
	ts := new_symbol('t')
	assert ts.name == 't'
}
