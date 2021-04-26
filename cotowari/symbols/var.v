module symbols

import cotowari.util { auto_id }

pub struct Var {
mut:
	scope &Scope = 0
pub:
	name string
	id   u64
pub mut:
	typ Type
}

pub fn new_var(name string, typ Type) Var {
	return Var{
		name: name
		typ: typ
		id: auto_id()
	}
}

pub fn new_placeholder_var(name string, typename string) Var {
	return new_var(name, new_placeholder_type(typename))
}

pub fn new_scope_var(name string, typ Type, scope &Scope) Var {
	mut v := new_var(name, typ)
	v.scope = scope
	return v
}

pub fn new_scope_placeholder_var(name string, typename string, scope &Scope) Var {
	return new_scope_var(name, new_placeholder_type(typename), scope)
}

pub fn new_fn(name string, args []Type, ret Type) Var {
	return new_var(name, new_type(name, FuncTypeInfo{args, ret}))
}

pub fn new_scope_fn(name string, args []Type, ret Type, scope &Scope) Var {
	mut v := new_fn(name, args, ret)
	v.scope = scope
	return v
}

pub fn new_placeholder_fn(name string, arg_typenames []string, ret_typename string) Var {
	return new_fn(name, arg_typenames.map(new_placeholder_type(it)), new_placeholder_type(ret_typename))
}

pub fn (v Var) str() string {
	return 'Var{ name: $v.name, scope: ${Symbol(v).scope_str()}, typ: $v.typ }'
}

pub fn (v Var) full_name() string {
	return Symbol(v).full_name()
}

pub fn (v Var) scope() ?&Scope {
	return Symbol(v).scope()
}
