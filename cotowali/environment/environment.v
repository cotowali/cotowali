// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module environment

import os
import cotowali.util { is_relative_path }

const env_prefixes = ['COTOWALI', 'LI']

enum EnvKey {
	cotowali_home
	cotowali_path
}

fn getenv(key EnvKey) ?string {
	s := match key {
		.cotowali_home { '_HOME' }
		.cotowali_path { '_PATH' }
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

pub fn executable() string {
	return os.executable()
}

fn cotowali_home_from_executable() string {
	exec := os.real_path(executable())
	$if !prod {
		if os.dir(exec).ends_with(os.join_path('cmd', 'lic')) {
			// v run
			return os.real_path(os.dir(@VMOD_FILE))
		}
	}
	// cotowali/bin -> cotowali
	return os.real_path(os.join_path(os.dir(exec), '../'))
}

pub fn cotowali_home() string {
	return if got := getenv(.cotowali_home) { got } else { cotowali_home_from_executable() }
}

pub fn cotowali_std() string {
	return os.join_path(cotowali_home(), 'std')
}

pub fn cotowali_builtin() string {
	return os.join_path(cotowali_std(), 'builtin.li')
}

[params]
pub struct CotowaliPathParams {
	no_std bool
}

pub fn cotowali_paths(params CotowaliPathParams) []string {
	mut paths := if path := getenv(.cotowali_path) {
		path.split(os.path_delimiter)
	} else {
		[]string{}
	}
	if !params.no_std {
		paths << cotowali_std()
	}
	return paths
}

pub fn find_file_path_in_cotowali_path(path string, params CotowaliPathParams) ?string {
	if is_relative_path(path) {
		return none
	}
	for dir in cotowali_paths() {
		try_path := os.join_path(dir, path)
		if os.is_file(try_path) {
			return os.real_path(try_path)
		}
	}
	return none
}
