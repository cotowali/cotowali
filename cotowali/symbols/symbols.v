// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.source { Pos }
import cotowali.util { nil_to_none }

const (
	reserved_id_max = 1000
)

type ID = u64

fn auto_id() ID {
	return util.rand_more_than[u64](symbols.reserved_id_max)
}

type Symbol = TypeSymbol | Var

[inline]
pub fn (v Symbol) scope() ?&Scope {
	return nil_to_none(v.scope)
}

fn (v Symbol) scope_str() string {
	return if scope := v.scope() { scope.str() } else { 'none' }
}

fn (v Symbol) id() ID {
	return match v {
		Var { v.id }
		TypeSymbol { u64(v.typ) }
	}
}

fn (v Symbol) pos() Pos {
	return v.pos
}
