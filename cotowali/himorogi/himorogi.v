// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module himorogi

import cotowali.source { Source }
import cotowali.context { Context }
import cotowali.compiler { parse_and_check }
import cotowali.himorogi.interpreter { new_interpreter }

pub fn run(s &Source, args []string, ctx &Context) ?int {
	f := parse_and_check(s, ctx) ?
	mut e := new_interpreter(ctx)
	return e.run(f)
}
