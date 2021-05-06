module symbols

import cotowari.source { Pos }
import cotowari.util { nil_to_none }

type Symbol = TypeSymbol | Var

[inline]
pub fn (v Symbol) scope() ?&Scope {
	return nil_to_none(v.scope)
}

pub fn (v Symbol) full_name() string {
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
