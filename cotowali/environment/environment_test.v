// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module environment

import os

fn test_get_env() ? {
	os.unsetenv('COTOWALI_HOME')
	os.unsetenv('LI_HOME')
	if _ := getenv(.cotowali_home) {
		assert false
	}

	os.setenv('LI_HOME', 'abc', true)
	assert (getenv(.cotowali_home)?) == 'abc'
	os.setenv('COTOWALI_HOME', 'xyz', true)
	assert (getenv(.cotowali_home)?) == 'xyz'
}
