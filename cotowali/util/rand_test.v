// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

fn test_rand() {
	for i in 0 .. 10 {
		v_u32 := rand_in_range<u32>(1, 5)
		v_u64 := rand_in_range<u64>(1, 5)
		v_int := rand_in_range<int>(1, 5)
		v_i64 := rand_in_range<i64>(1, 5)

		assert typeof(v_u32).name == 'u32'
		assert typeof(v_u64).name == 'u64'
		assert typeof(v_int).name == 'int'
		assert typeof(v_i64).name == 'i64'

		assert 1 <= v_u32 && v_u32 < 5
		assert 1 <= v_u64 && v_u64 < 5
		assert 1 <= v_int && v_int < 5
		assert 1 <= v_i64 && v_i64 < 5
	}

	for i in 0 .. 10 {
		v_u32 := rand_n<u32>(5)
		v_u64 := rand_n<u64>(5)
		v_int := rand_n<int>(5)
		v_i64 := rand_n<i64>(5)

		assert typeof(v_u32).name == 'u32'
		assert typeof(v_u64).name == 'u64'
		assert typeof(v_int).name == 'int'
		assert typeof(v_i64).name == 'i64'

		assert 0 <= v_u32 && v_u32 < 5
		assert 0 <= v_u64 && v_u64 < 5
		assert 0 <= v_int && v_int < 5
		assert 0 <= v_i64 && v_i64 < 5
	}

	for i in 0 .. 10 {
		v_u32 := rand<u32>()
		v_u64 := rand<u64>()
		v_int := rand<int>()
		v_i64 := rand<i64>()

		assert typeof(v_u32).name == 'u32'
		assert typeof(v_u64).name == 'u64'
		assert typeof(v_int).name == 'int'
		assert typeof(v_i64).name == 'i64'
	}

	for i in 0 .. 10 {
		v_u32 := rand_more_than<u32>(10)
		v_u64 := rand_more_than<u64>(10)
		v_int := rand_more_than<int>(10)
		v_i64 := rand_more_than<i64>(10)

		assert typeof(v_u32).name == 'u32'
		assert typeof(v_u64).name == 'u64'
		assert typeof(v_int).name == 'int'
		assert typeof(v_i64).name == 'i64'

		assert v_u32 > 10
		assert v_u64 > 10
		assert v_int > 0
		assert v_i64 > 0
	}
}
