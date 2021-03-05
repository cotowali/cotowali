module source

fn test_is_whitespace() {
	true_inputs := [' ', '　']
	false_inputs := ['a', '', '\n', '\r']

	for c in true_inputs {
		assert Letter(c).@is(.whitespace)
	}

	for c in false_inputs {
		assert !Letter(c).@is(.whitespace)
	}
}

fn test_is_alphabet() {
	assert !Letter('Ａ').@is(.alphabet)
	assert Letter('A').@is(.alphabet)
	assert Letter('Z').@is(.alphabet)
	assert Letter('a').@is(.alphabet)
	assert Letter('z').@is(.alphabet)
}

fn test_is_digit() {
	assert !Letter('０').@is(.digit)
	assert Letter('0').@is(.digit)
	assert Letter('9').@is(.digit)
}

fn test_rune() {
	assert Letter('あ').rune() == `あ`
}
