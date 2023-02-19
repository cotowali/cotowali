// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sha3

pub const (
	size224 = 28
	size256 = 32
	size384 = 48
	size512 = 64
)

pub fn sum224(data []u8) []u8 {
	return sha3(data, sha3.size224)
}

pub fn sum256(data []u8) []u8 {
	return sha3(data, sha3.size256)
}

pub fn sum384(data []u8) []u8 {
	return sha3(data, sha3.size384)
}

pub fn sum512(data []u8) []u8 {
	return sha3(data, sha3.size512)
}

pub fn hexhash_224(s string) string {
	return sum224(s.bytes()).hex()
}

pub fn hexhash_256(s string) string {
	return sum256(s.bytes()).hex()
}

pub fn hexhash_384(s string) string {
	return sum384(s.bytes()).hex()
}

pub fn hexhash_512(s string) string {
	return sum512(s.bytes()).hex()
}
