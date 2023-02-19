// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

import rand as v_rand

pub fn rand_in_range[T](min T, max T) T {
	$if T is u32 {
		return v_rand.u32_in_range(min, max) or { li_panic(@FN, @FILE, @LINE, err.msg()) }
	} $else $if T is u64 {
		return v_rand.u64_in_range(min, max) or { li_panic(@FN, @FILE, @LINE, err.msg()) }
	} $else $if T is int {
		return v_rand.int_in_range(min, max) or { li_panic(@FN, @FILE, @LINE, err.msg()) }
	} $else $if T is i64 {
		return v_rand.i64_in_range(min, max) or { li_panic(@FN, @FILE, @LINE, err.msg()) }
	}
	panic('invalid type')
}

pub fn rand[T]() T {
	$if T is u32 {
		return v_rand.u32()
	} $else $if T is u64 {
		return v_rand.u64()
	} $else $if T is int {
		return v_rand.int()
	} $else $if T is i64 {
		return v_rand.i64()
	}
	panic('invalid type')
}

pub fn rand_n[T](n T) T {
	$if T is u32 {
		return v_rand.u32n(n) or { li_panic(@FN, @FILE, @LINE, err.msg()) }
	} $else $if T is u64 {
		return v_rand.u64n(n) or { li_panic(@FN, @FILE, @LINE, err.msg()) }
	} $else $if T is int {
		return v_rand.intn(n) or { li_panic(@FN, @FILE, @LINE, err.msg()) }
	} $else $if T is i64 {
		return v_rand.i64n(n) or { li_panic(@FN, @FILE, @LINE, err.msg()) }
	}
	panic('invalid type')
}

pub fn rand_more_than[T](n T) T {
	return rand_in_range[T](n + 1, const_max[T]())
}
