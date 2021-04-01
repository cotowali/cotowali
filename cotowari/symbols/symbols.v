module symbols

pub type Symbol = Type | Var

pub fn (sym Symbol) scope() ?&Scope {
	if isnil(sym.scope) {
		return none
	}
	return sym.scope
}

fn (sym Symbol) scope_str() string {
	return if scope := sym.scope() {
		scope.str()
	} else {
		'none'
	}
}

pub fn (sym Symbol) full_name() string {
	name := if sym.name.len > 0 { sym.name } else { 'sym$sym.id' }
	if s := sym.scope() {
		if s.is_global() {
			return name
		}
		return join_name(s.full_name(), name)
	} else {
		return name
	}
}
