// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checksum

import crypto.md5
import crypto.sha1
import crypto.sha256

pub enum Algorithm {
	md5
	sha1
	sha256
}

pub fn hexhash(algo Algorithm, data string) string {
	return match algo {
		.md5 { md5.hexhash(data) }
		.sha1 { sha1.hexhash(data) }
		.sha256 { sha256.hexhash(data) }
	}
}
