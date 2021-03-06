module util

fn test_in() {
	assert @in(0, 0, 1)
	assert @in(1, 0, 1)
	assert !@in(2, 0, 1)

	assert @in('c', 'a', 'z')

	assert in2('c', '0', '2', 'a', 'c')
	assert in2('1', '0', '2', 'a', 'c')
	assert !in2('9', '0', '2', 'a', 'c')
	assert !in2('z', '0', '2', 'a', 'c')
}
