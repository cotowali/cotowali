module util

import math

pub fn const_max<T>() T {
	$if T is u32 {
		return u32(math.max_u32)
	} $else $if T is u64 {
		return u64(math.max_u64)
	} $else $if T is int {
		return int(math.max_i32)
	} $else $if T is i64 {
		return i64(math.max_i64)
	}
	panic('Invalid type')
}

pub fn const_min<T>() T {
	$if T is u32 {
		return u32(0)
	} $else $if T is u64 {
		return u64(0)
	} $else $if T is int {
		return int(math.min_i32)
	} $else $if T is i64 {
		return i64(math.min_i64)
	}
	panic('Invalid type')
}

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
