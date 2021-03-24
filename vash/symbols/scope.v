module symbols

import vash.util { auto_id }

pub struct Scope {
pub:
	id u64
mut:
	parent   &Scope
	children []&Scope
	symbols  map[string]Symbol
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

pub fn new_scope(parent &Scope) &Scope {
	return &Scope{
		id: auto_id()
		parent: parent
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

pub fn (mut s Scope) create_child() &Scope {
	child := new_scope(s)
	s.children << child
	return child
}

[inline]
fn (mut s Scope) must_register(sym Symbol) Symbol {
	return s.register(sym) or { panic(err) }
}

pub fn (mut s Scope) register(sym Symbol) ?Symbol {
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
	s.symbols[key] = sym
	return sym
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
