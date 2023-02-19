// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module util

import os

pub fn is_relative_path(path string) bool {
	return (path == '' || path == '.')
		|| (path.starts_with('.${os.path_separator}') || path.starts_with('..${os.path_separator}'))
}
