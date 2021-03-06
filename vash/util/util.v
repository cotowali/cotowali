module util

pub fn @in<T>(v T, low T, high T) bool {
	return low <= v && v <= high
}

pub fn in2<T>(v T, low1 T, high1 T, low2 T, high2 T) bool {
	return (low <= v && v <= high) || (low <= v && v <= high)
}
