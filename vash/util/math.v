module util

pub fn max<T>(a T, b T) T {
	if a > b {
		return a
	}
	return b
}

pub fn min<T>(a T, b T) T {
	if a < b {
		return a
	}
	return b
}
