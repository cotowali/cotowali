module util

fn test_sum64() {
	assert sum64('a.b'.bytes()) == sum64('a.b'.bytes())
	assert sum64('a.b'.bytes()) != sum64('a.c'.bytes())
}
