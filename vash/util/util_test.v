module util

fn test_in() {
	assert @in(0, 0, 1)
	assert @in(1, 0, 1)
	assert !@in(2, 0, 1)

	assert @in('c', 'a', 'z')
}
