module scope

import vash.util { auto_id }

pub type ScopeObject = Var | TypeSymbol

pub struct Var {
pub:
	name string
	id  u64
pub mut:
	typ TypeSymbol
}

pub fn new_var(name string) Var {
	return Var {
		name: name
		typ: unknown_type
		id: auto_id()
	}
}

pub struct Scope {
pub:
	id u64
mut:
	parent &Scope
	children []&Scope
	objects map[string]ScopeObject
}

pub fn new_global_scope() &Scope {
	return &Scope {
		id: 1
		parent: 0
	}
}

pub fn new_scope(parent &Scope) &Scope {
	return &Scope {
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

pub fn (mut s Scope) create() &Scope {
	child := new_scope(s)
	s.children << child
	return child
}

pub fn (mut s Scope) register(object ScopeObject) ?ScopeObject {
	$if !prod {
		if object.id == 0 {
			dump(object)
			panic('object.id is not assigned')
		}
	}
	key := object.name
	if key in s.objects {
		return error('$key is exists')
	}
	s.objects[key] = object
	return object
}

pub fn (s &Scope) lookup(name string) ?ScopeObject {
	if name in s.objects {
		return s.objects[name]
	}
	if p := s.parent() {
		return p.lookup(name)
	}
	return none
}
