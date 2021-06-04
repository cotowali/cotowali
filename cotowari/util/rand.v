module util

import rand

pub fn rand_in_range<T>(min T, max T) T {
	$if T is u32 {
		return rand.u32_in_range(min, max)
	} $else $if T is u64 {
		return rand.u64_in_range(min, max)
	} $else $if T is int {
		return rand.int_in_range(min, max)
	} $else $if T is i64 {
		return rand.i64_in_range(min, max)
	}
	panic('invalid type')
}

pub fn rand<T>() T {
	$if T is u32 {
		return rand.u32()
	} $else $if T is u64 {
		return rand.u64()
	} $else $if T is int {
		return rand.int()
	} $else $if T is i64 {
		return rand.i64()
	}
	panic('invalid type')
}

pub fn rand_n<T>(n T) T {
	$if T is u32 {
		return rand.u32n(n)
	} $else $if T is u64 {
		return rand.u64n(n)
	} $else $if T is int {
		return rand.intn(n)
	} $else $if T is i64 {
		return rand.i64n(n)
	}
	panic('invalid type')
}

pub fn rand_more_than<T>(n T) T {
	return rand_in_range<T>(n + 1, const_max<T>())
}
