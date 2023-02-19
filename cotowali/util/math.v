// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

import math

pub fn const_max[T]() T {
	$if T is u32 {
		return u32(math.max_u32)
	} $else $if T is u64 {
		return u64(math.max_u64)
	} $else $if T is int {
		return int(math.max_i32)
	} $else $if T is i64 {
		return i64(math.max_i64)
	}
	li_panic(@FN, @FILE, @LINE, 'Invalid type')
}

pub fn const_min[T]() T {
	$if T is u32 {
		return u32(0)
	} $else $if T is u64 {
		return u64(0)
	} $else $if T is int {
		return int(math.min_i32)
	} $else $if T is i64 {
		return i64(math.min_i64)
	}
	li_panic(@FN, @FILE, @LINE, 'Invalid type')
}

pub fn abs[T](v T) T {
	if v < 0 {
		return -v
	}
	return v
}

pub fn max[T](a T, b T) T {
	if a > b {
		return a
	}
	return b
}

pub fn min[T](a T, b T) T {
	if a < b {
		return a
	}
	return b
}
