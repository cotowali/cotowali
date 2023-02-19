// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checksum

fn test_hexhash() {
	vv := 'cotowali'
	assert hexhash(.md5, '') == 'd41d8cd98f00b204e9800998ecf8427e'
	assert hexhash(.md5, vv) == '964264edfcad27eab4ac3b9aac8eb94a'
	assert hexhash(.sha1, '') == 'da39a3ee5e6b4b0d3255bfef95601890afd80709'
	assert hexhash(.sha1, vv) == 'be4df22489c03918cd974c2122062e97797c7460'
	assert hexhash(.sha256, '') == 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
	assert hexhash(.sha256, vv) == '612816a1a58922bdf6b3c3b62c6862d5a119617d0246148138684376be96a289'
}
