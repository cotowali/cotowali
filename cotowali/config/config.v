// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module config

import os
import cotowali.util { li_panic }

pub enum Backend {
	sh
	dash
	bash
	zsh
	pwsh
	ush
	himorogi
}

pub fn (b Backend) is_sh_like() bool {
	return b in [.sh, .dash, .bash, .zsh]
}

pub fn (b Backend) shebang() string {
	return match b {
		.sh { '#!/bin/sh' }
		.dash { '#!/usr/bin/env dash' }
		.bash { '#!/usr/bin/env dash' }
		.zsh { '#!/usr/bin/env dash' }
		.pwsh { '#!/usr/bin/env pwsh' }
		.ush { '' }
		.himorogi { '' }
	}
}

pub fn (backend Backend) find_executable_path() ?string {
	if backend == .ush {
		return Backend.sh.find_executable_path() or {
			if pwsh := Backend.pwsh.find_executable_path() {
				return pwsh
			}
			return err
		}
	}

	cmds := match backend {
		.pwsh { ['pwsh', 'pwsh.exe', 'powershell.exe'] }
		.sh { ['sh'] }
		.dash { ['dash'] }
		.bash { ['bash', 'bash.exe'] }
		.zsh { ['zsh'] }
		.ush { panic('') }
		.himorogi { ['himorogi'] }
	}
	for cmd in cmds {
		if found := os.find_abs_path_of_executable(cmd) {
			return found
		}
	}
	return error('${backend} not found')
}

pub fn (backend Backend) script_ext() string {
	return match backend {
		.sh, .dash { '.sh' }
		.bash { '.bash' }
		.zsh { '.zsh' }
		.pwsh { '.ps1' }
		.ush { '.ush' }
		.himorogi { li_panic(@FN, @FILE, @LINE, '') }
	}
}

[flag]
pub enum Feature {
	warn_all
	interactive
	shebang
}

pub fn default_feature() Feature {
	return Feature.shebang
}

pub fn (mut f Feature) set_by_str(s string) ? {
	match s {
		'warn_all' { f.set(.warn_all) }
		else { return error('unknown feature `${s}`') }
	}
}

[params]
pub struct Config {
pub mut:
	backend    Backend = .sh
	feature    Feature
	no_emit    bool
	no_builtin bool
	is_test    bool
	indent     string = '  '
}

pub fn backend_from_str(s string) ?Backend {
	match s {
		'sh' { return .sh }
		'dash' { return .dash }
		'bash' { return .bash }
		'zsh' { return .zsh }
		'pwsh', 'powershell' { return .pwsh }
		'ush', 'universal' { return .ush }
		'himorogi' { return .himorogi }
		else { return error('unknown backend `${s}`') }
	}
}
