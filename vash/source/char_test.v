module source


fn test_rune() {
	assert Char('あ').rune() == `あ`
}

fn test_is_not() {
	assert Char('a').is_not(.whitespace)
	assert !Char(' ').is_not(.whitespace)
}

fn test_is_whitespace() {
	true_inputs := [' ', '　']
	false_inputs := ['a', '', '\n', '\r']

	for c in true_inputs {
		assert Char(c).@is(.whitespace)
	}

	for c in false_inputs {
		assert !Char(c).@is(.whitespace)
	}
}

fn test_is_alphabet() {
	assert !Char('Ａ').@is(.alphabet)
	assert Char('A').@is(.alphabet)
	assert Char('Z').@is(.alphabet)
	assert Char('a').@is(.alphabet)
	assert Char('z').@is(.alphabet)
}

fn test_is_digit() {
	assert !Char('０').@is(.digit)
	assert Char('0').@is(.digit)
	assert Char('9').@is(.digit)
	assert !Char('a').@is(.digit)

	assert !Char('０').@is(.hex_digit)
	assert Char('0').@is(.hex_digit)
	assert Char('a').@is(.hex_digit)
	assert Char('F').@is(.hex_digit)
	assert !Char('g').@is(.hex_digit)
	assert !Char('G').@is(.hex_digit)

	assert !Char('０').@is(.oct_digit)
	assert Char('0').@is(.oct_digit)
	assert Char('7').@is(.oct_digit)
	assert !Char('8').@is(.oct_digit)
	assert !Char('9').@is(.oct_digit)
	assert !Char('a').@is(.oct_digit)

	assert !Char('０').@is(.binary_digit)
	assert Char('0').@is(.binary_digit)
	assert Char('1').@is(.binary_digit)
	assert !Char('2').@is(.binary_digit)
	assert !Char('a').@is(.binary_digit)
}
