// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
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

fn auto_id() ID {
	return util.rand_more_than<u64>(symbols.reserved_id_max)
}

type Symbol = TypeSymbol | Var

[inline]
pub fn (v Symbol) scope() ?&Scope {
	return nil_to_none(v.scope)
}

pub fn (v Symbol) name_for_ident() string {
	id := match v {
		Var { v.id }
		TypeSymbol { u64(v.typ) }
	}
	name := if v.name.len > 0 { v.name } else { 'sym$id' }
	if s := v.scope() {
		if s.is_global() {
			return name
		}
		return join_name(s.full_name(), name)
	} else {
		return name
	}
}

fn (v Symbol) scope_str() string {
	return if scope := v.scope() { scope.str() } else { 'none' }
}

fn (v Symbol) pos() Pos {
	return v.pos
}
