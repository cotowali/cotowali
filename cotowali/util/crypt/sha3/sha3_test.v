// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module sha3

fn test_256() {
	cases := {
		'':      [
			'6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7',
			'a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a',
			'0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2a' +
				'c3713831264adb47fb6bd1e058d5f004',
			'a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a6' +
				'15b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26',
		]
		'hello': [
			'b87f88c72702fff1748e58b87e9141a42c0dbedc29a78cb0d4a5cd81',
			'3338be694f50c5f338814986cdf0686453a888b84f424d792af4b9202398f392',
			'720aea11019ef06440fbf05d87aa24680a2153df3907b23631e7177ce620fa13' +
				'30ff07c0fddee54699a4c3ee0ee9d887',
			'75d527c368f2efe848ecf6b073a36767800805e9eef2b1857d5f984f036eb6df' +
				'891d75f72d9b154518c1cd58835286d1da9a38deba3de98b5a53e5ed78a84976',
		]
	}
	for input, expected in cases {
		assert sum224(input.bytes()).hex() == expected[0]
		assert sum256(input.bytes()).hex() == expected[1]
		assert sum384(input.bytes()).hex() == expected[2]
		assert sum512(input.bytes()).hex() == expected[3]
		assert hexhash_224(input) == expected[0]
		assert hexhash_256(input) == expected[1]
		assert hexhash_384(input) == expected[2]
		assert hexhash_512(input) == expected[3]
	}
}
