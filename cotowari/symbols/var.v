module symbols

pub struct Var {
mut:
	scope &Scope = 0
pub:
	name string
	id   u64
pub mut:
	typ Type = builtin_type(.placeholder)
}

pub fn (v Var) str() string {
	return 'Var{ name: $v.name, scope: $v.scope_str(), typ: $v.typ }'
}

pub fn (v Var) scope() ?&Scope {
	return Symbol(v).scope()
}

fn (v Var) scope_str() string {
	return Symbol(v).scope_str()
}

pub fn (v Var) full_name() string {
	return Symbol(v).full_name()
}

pub fn (v Var) type_symbol() TypeSymbol {
	if scope := v.scope() {
		return scope.lookup_type(v.typ) or { unresolved_type_symbol }
	}
	return unresolved_type_symbol
}
