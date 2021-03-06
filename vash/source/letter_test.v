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
	assert !Letter('a').@is(.digit)

	assert !Letter('０').@is(.hex_digit)
	assert Letter('0').@is(.hex_digit)
	assert Letter('a').@is(.hex_digit)
	assert Letter('F').@is(.hex_digit)
	assert !Letter('g').@is(.hex_digit)
	assert !Letter('G').@is(.hex_digit)

	assert !Letter('０').@is(.oct_digit)
	assert Letter('0').@is(.oct_digit)
	assert Letter('7').@is(.oct_digit)
	assert !Letter('8').@is(.oct_digit)
	assert !Letter('9').@is(.oct_digit)
	assert !Letter('a').@is(.oct_digit)

	assert !Letter('０').@is(.binary_digit)
	assert Letter('0').@is(.binary_digit)
	assert Letter('1').@is(.binary_digit)
	assert !Letter('2').@is(.binary_digit)
	assert !Letter('a').@is(.binary_digit)
}

fn test_rune() {
	assert Letter('あ').rune() == `あ`
}
