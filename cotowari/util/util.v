module util

pub fn @in<T>(v T, low T, high T) bool {
	return low <= v && v <= high
}

pub fn in2<T>(v T, low1 T, high1 T, low2 T, high2 T) bool {
	return (low1 <= v && v <= high1) || (low2 <= v && v <= high2)
}

[inline]
pub fn nil_to_none<T>(ref &T) ?&T {
	return if isnil(ref) { none } else { ref }
}

pub fn panic_and_value<T>(msg string, v T) T {
	panic(msg)
	return v
}
