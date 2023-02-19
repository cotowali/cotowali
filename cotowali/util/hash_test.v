// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

fn test_sum64() {
	assert sum64('a.b'.bytes()) == sum64('a.b'.bytes())
	assert sum64('a.b'.bytes()) != sum64('a.c'.bytes())
}
