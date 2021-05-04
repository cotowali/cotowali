module symbols

import cotowari.util { auto_id }

pub fn (mut s Scope) register_builtin() {
	for ts in builtin.type_symbols {
		s.must_register_type(ts)
	}
}

fn (mut s Scope) check_before_register_var(v Var) ? {
	key := v.name
	if key in s.vars {
		return error('$key is exists')
	}
}

pub fn (mut s Scope) register_var(v Var) ?Var {
	s.check_before_register_var(v) ?
	new_v := Var{
		...v
		id: if v.id == 0 { auto_id() } else { v.id }
		scope: s
	}
	s.vars[new_v.name] = new_v
	return new_v
}

pub fn (s &Scope) lookup_var(name string) ?Var {
	if name in s.vars {
		return s.vars[name]
	}
	if p := s.parent() {
		return p.lookup_var(name)
	}
	return none
}

pub fn (mut s Scope) register_fn(name string, args []Type, ret Type) Var {
	/*
	TODO
	info := FunrctionTypeInfo { args, ret }
	name := info.signature()
	fn_type := s.register_or_lookup_type(name: name, info: info)
	return s.register_var(name, fn_type)
	*/
	return Var{}
}

fn (s &Scope) must_lookup_var(name string) Var {
	return s.lookup_var(name) or { panic(err) }
}

pub fn (mut s Scope) lookup_or_register_var(v Var) Var {
	return s.lookup_var(v.name) or { s.register_var(v) or { panic(err) } }
}
