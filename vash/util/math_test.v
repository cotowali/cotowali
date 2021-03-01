module util

fn test_max() {
	assert max(0, 1) == 1
	assert max(1.0, 0.0) == 1
	assert max('a', 'b') == 'b'
}

fn test_min() {
	assert min(0, 1) == 0
	assert min(1.0, 0.0) == 0.0
	assert min('a', 'b') == 'a'
}
