module symbols

import vash.util { auto_id }

pub struct Scope {
pub:
	id   u64
	name string
mut:
	parent   &Scope
	children []&Scope
	symbols  map[string]Symbol
}

fn join_name(names ...string) string {
	return names.join('_')
}

pub const global_id = 1

pub fn new_global_scope() &Scope {
	mut s := &Scope{
		id: symbols.global_id
		parent: 0
	}
	s.must_register(unknown_type)
	return s
}

pub fn new_scope(name string, parent &Scope) &Scope {
	return &Scope{
		id: auto_id()
		name: name
		parent: parent
	}
}

pub fn (s &Scope) is_global() bool {
	return s.id == symbols.global_id
}

pub fn (s &Scope) full_name() string {
	name := if s.name.len > 0 { s.name } else { 'scope$s.id' }
	if p := s.parent() {
		if p.is_global() {
			return name
		}
		return join_name(p.full_name(), name)
	} else {
		return name
	}
}

pub fn (s &Scope) parent() ?&Scope {
	if isnil(s.parent) {
		return none
	}
	return s.parent
}

pub fn (s &Scope) children() []&Scope {
	return s.children
}

pub fn (mut s Scope) create_child(name string) &Scope {
	child := new_scope(name, s)
	s.children << child
	return child
}

[inline]
fn (mut s Scope) must_register(sym Symbol) Symbol {
	return s.register(sym) or { panic(err) }
}

fn (mut s Scope) check_before_register(sym Symbol) ? {
	$if !prod {
		if sym.id == 0 {
			dump(sym)
			panic('sym.id is not assigned')
		}
	}
	key := sym.name
	if key in s.symbols {
		return error('$key is exists')
	}
}

pub fn (mut s Scope) register_var(v Var) ?Var {
	s.check_before_register(v) ?
	sym := Var{...v, scope: s}
	s.symbols[sym.name] = Symbol(sym)
	return sym
}

pub fn (mut s Scope) register_type(v Type) ?Type {
	s.check_before_register(v) ?
	sym := Type{...v, scope: s}
	s.symbols[sym.name] = Symbol(sym)
	return sym
}

pub fn (mut s Scope) register(sym Symbol) ?Symbol {
	// because compiler bug, `retrun match sym` couldn't be use
	match sym {
		Var { return Symbol(s.register_var(sym) ?) }
		Type { return Symbol(s.register_type(sym) ?) }
	}
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

pub fn (s &Scope) ident_for(sym Symbol) string {
	if s.id == symbols.global_id {
		return sym.name
	}
	return 's${s.id}_$sym.name'
}
