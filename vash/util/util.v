module util

pub fn @in<T>(v T, low T, high T) bool {
	return low <= v && v <= high
}
