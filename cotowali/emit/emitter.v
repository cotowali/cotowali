// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module emit

import io
import cotowali.ast { File }
import cotowali.context { Context }
import cotowali.emit.sh
import cotowali.emit.powershell

pub interface Emitter {
mut:
	emit(f &File)
}

pub fn new_emitter(out io.Writer, ctx &Context) Emitter {
	// avoid V's bug (segfault) by store to variable
	match ctx.config.backend {
		.sh, .dash, .bash, .zsh {
			mut e := sh.new_emitter(out, ctx)
			return e
		}
		.powershell {
			mut e := powershell.new_emitter(out, ctx)
			return e
		}
	}
}
