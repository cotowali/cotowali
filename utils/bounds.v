module utils

[inline]
pub fn check_bounds_if_required(len int, begin int, end int) {
	$if !no_bounds_checking ? {
		if begin > end || begin > len || end > len || begin < 0 || begin < 0 {
			panic('slice($begin, $end) out of bounds (len=$len)')
		}
	}
}
