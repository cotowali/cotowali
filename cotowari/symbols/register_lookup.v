module symbols

import cotowari.util { auto_id }

pub fn (mut s Scope) register_builtin() {
	for ts in builtin.type_symbols {
		s.must_register_type(ts)
	}
}

[inline]
fn (mut s Scope) must_register(sym Symbol) Symbol {
	return s.register(sym) or { panic(err) }
}

fn (mut s Scope) must_register_multi(syms ...Symbol) []Symbol {
	return syms.map(s.must_register(it))
}

fn (mut s Scope) check_before_register(sym Symbol) ? {
	key := sym.name
	if key in s.symbols {
		return error('$key is exists')
	}
}

pub fn (mut s Scope) register_var(v Var) ?Var {
	s.check_before_register(v) ?
	sym := Var{
		...v
		id: if v.id == 0 { auto_id() } else { v.id }
		scope: s
	}
	s.symbols[sym.name] = Symbol(sym)
	return sym
}

pub fn (mut s Scope) register(sym Symbol) ?Symbol {
	// because compiler bug, `retrun match sym` couldn't be use
	return Symbol(s.register_var(sym) ?)
}

pub fn (s &Scope) lookup_var(name string) ?Var {
	if found := s.lookup(name) {
		return found
	}
	return none
}

pub fn (s &Scope) must_lookup_var(name string) Var {
	return s.lookup_var(name) or { panic(err) }
}

pub fn (s &Scope) lookup(name string) ?Symbol {
	if name in s.symbols {
		return s.symbols[name]
	}
	if p := s.parent() {
		return p.lookup(name)
	}
	return none
}

pub fn (s &Scope) must_lookup(name string) Symbol {
	return s.lookup(name) or { panic(err) }
}

pub fn (mut s Scope) lookup_or_register_var(v Var) Var {
	return s.lookup_var(v.name) or { s.register_var(v) or { panic(err) } }
}

pub fn (mut s Scope) lookup_or_register(v Symbol) Symbol {
	return s.lookup(v.name) or { s.register(v) or { panic(err) } }
}

fn (s &Scope) check_before_register_type(ts TypeSymbol) ? {
	if int(ts.typ) in s.type_symbols {
		return error('$ts.typ is exists')
	}
	if ts.name.len > 0 && ts.name in s.name_to_type {
		return error('$ts.name is exists')
	}
}

pub fn (mut s Scope) register_type(ts TypeSymbol) ?TypeSymbol {
	s.check_before_register_type(ts) ?
	typ := if ts.typ == 0 { Type(int(auto_id())) } else { ts.typ }
	new_ts := TypeSymbol{
		...ts
		typ: typ
	}
	s.type_symbols[int(typ)] = new_ts
	if new_ts.name.len > 0 {
		s.name_to_type[new_ts.name] = new_ts.typ
	}
	return new_ts
}

[inline]
fn (mut s Scope) must_register_type(ts TypeSymbol) TypeSymbol {
	return s.register_type(ts) or { panic(err) }
}

type TypeOrName = Type | string

// pub fn (s &Scope) lookup_type(key Type | string) ?TypeSymbol {
pub fn (s &Scope) lookup_type(key TypeOrName) ?TypeSymbol {
	// dont use `int_typ := if ...` to avoid compiler bug
	mut int_typ := 0
	if key is string {
		if key in s.name_to_type {
			int_typ = s.name_to_type[key]
		} else if p := s.parent() {
			return p.lookup_type(key)
		} else {
			return none
		}
	} else {
		int_typ = int(key as Type)
	}

	if int_typ in s.type_symbols {
		return s.type_symbols[int_typ]
	}
	if p := s.parent() {
		return p.lookup_type(key)
	}
	return none
}

pub fn (s &Scope) must_lookup_type(key TypeOrName) TypeSymbol {
	return s.lookup_type(key) or { panic(err) }
}

pub fn (mut s Scope) lookup_or_register_type(ts TypeSymbol) TypeSymbol {
	if ts.name.len > 0 {
		return s.lookup_type(ts.name) or { s.register_type(ts) or { panic(err) } }
	}
	return s.lookup_type(ts.typ) or { s.register_type(ts) or { panic(err) } }
}
