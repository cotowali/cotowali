module source

fn test_is_whitespace() {
	true_inputs := [' ', '　']
	false_inputs := ['a', '', '\n', '\r']

	for c in true_inputs {
		assert Letter(c).is_whitespace()
	}

	for c in false_inputs {
		assert !Letter(c).is_whitespace()
	}
}

fn test_rune() {
	assert Letter('あ').rune() == `あ`
}
