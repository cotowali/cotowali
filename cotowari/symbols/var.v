module symbols

import cotowari.util { auto_id }

pub struct Var {
	scope &Scope = 0
pub:
	name string
	id   u64
pub mut:
	typ &Type
}

pub fn new_var(name string) &Var {
	return &Var{
		name: name
		typ: new_type('placeholder', PlaceholderTypeInfo{})
		id: auto_id()
	}
}

pub fn new_fn(name string) &Var {
	return &Var{
		name: name
		typ: new_type('placeholder_fn', PlaceholderTypeInfo{ is_fn: true })
		id: auto_id()
	}
}

pub fn (v Var) full_name() string {
	return Symbol(v).full_name()
}

pub fn (v Var) scope() ?&Scope {
	return Symbol(v).scope()
}
