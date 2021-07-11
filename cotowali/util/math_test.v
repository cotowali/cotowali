// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

fn test_max() {
	assert max(0, 1) == 1
	assert max(1.0, 0.0) == 1
	assert max('a', 'b') == 'b'
}

fn test_min() {
	assert min(0, 1) == 0
	assert min(1.0, 0.0) == 0.0
	assert min('a', 'b') == 'a'
}

fn test_abs() {
	assert abs(-1) == 1
	assert abs(1.1) == 1.1
}
