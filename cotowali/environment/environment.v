// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module environment

import os

const env_prefixes = ['COTOWALI', 'LI']

enum EnvKey {
	cotowali_home
}

fn getenv(key EnvKey) ?string {
	s := match key {
		.cotowali_home { '_HOME' }
	}
	if s[0] == `_` {
		for prefix in environment.env_prefixes {
			if value := os.getenv_opt('$prefix$s') {
				return value
			}
		}
		return none
	} else {
		return os.getenv_opt(s)
	}
}
