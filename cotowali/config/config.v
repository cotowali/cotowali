// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module config

import os

pub enum Backend {
	sh
	dash
	bash
	zsh
	pwsh
}

pub fn (b Backend) shebang() string {
	return match b {
		.sh { '#!/bin/sh' }
		.dash { '#!/usr/bin/env dash' }
		.bash { '#!/usr/bin/env dash' }
		.zsh { '#!/usr/bin/env dash' }
		.pwsh { '#!/usr/bin/env pwsh' }
	}
}

pub fn (backend Backend) find_executable_path() ?string {
	cmds := match backend {
		.pwsh { ['pwsh', 'pwsh.exe', 'powershell.exe'] }
		.sh { ['sh'] }
		.dash { ['dash'] }
		.bash { ['bash', 'bash.exe'] }
		.zsh { ['zsh'] }
	}
	for cmd in cmds {
		if found := os.find_abs_path_of_executable(cmd) {
			return found
		}
	}
	return error('$backend not found')
}

pub fn (backend Backend) script_ext() string {
	return match backend {
		.sh, .dash { '.sh' }
		.bash { '.bash' }
		.zsh { '.zsh' }
		.pwsh { '.ps1' }
	}
}

[flag]
pub enum Feature {
	warn_all
	interactive
	shebang
}

pub fn default_feature() Feature {
	mut f := Feature(0)
	f.set(.shebang)
	return f
}

pub fn (mut f Feature) set_by_str(s string) ? {
	match s {
		'warn_all' { f.set(.warn_all) }
		else { return error('unknown feature `$s`') }
	}
}

pub struct Config {
pub mut:
	backend Backend = .sh
	feature Feature
	no_emit bool
	no_std  bool
	indent  string = '  '
}

pub fn backend_from_str(s string) ?Backend {
	match s {
		'sh' { return .sh }
		'dash' { return .dash }
		'bash' { return .bash }
		'zsh' { return .zsh }
		'pwsh', 'powershell' { return .pwsh }
		else { return error('unknown backend `$s`') }
	}
}
