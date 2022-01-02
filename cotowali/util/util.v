// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

pub struct Unit {}

pub type Either<T, U> = T | U

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

pub fn struct_name<T>(v T) string {
	// SumTypeName(SumTypeName2(mod.Struct{
	mut s := v.str().split_into_lines()[0]
	s = s.split('(').last()
	s = s.split('{').first()

	// if struct has custom str, use typeof
	s = if s.len > 0 { s } else { typeof(v).name }

	return s.split('.').last()
}

[unsafe]
pub fn str_to_bytes_unsafe(s string) []byte {
	buf := []byte{len: s.len}
	unsafe {
		buf.data = s.str
	}
	return buf
}

pub fn to_octal(num int) string {
	buf_len := num / 8 + 2 // ceil(num / 8) + '\0'
	unsafe {
		buf := malloc_noscan(buf_len)
		count := C.snprintf(&char(buf), buf_len, c'%o', num)
		return tos(buf, count)
	}
}
