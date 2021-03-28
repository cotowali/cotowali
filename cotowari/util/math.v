module util

pub fn abs<T>(v T) T {
	if v < 0 {
		return -v
	}
	return v
}

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
