module utils

fn max<T>(a T, b T) T {
	if a > b {
		return a
	}
	return b
}

fn min<T>(a T, b T) T {
	if a < b {
		return a
	}
	return b
}
