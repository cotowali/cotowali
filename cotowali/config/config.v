// Copyright (c) 2021 The Cotowali Authors. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module config

pub enum Backend {
	sh
	dash
	bash
	zsh
	powershell
}

pub struct Config {
pub mut:
	backend Backend = .sh
	no_emit bool
	indent  string = '  '
}

pub fn backend_from_str(s string) ?Backend {
	match s {
		'sh' { return .sh }
		'dash' { return .dash }
		'bash' { return .bash }
		'zsh' { return .zsh }
		else { return error('unknown backend `$s`') }
	}
}
