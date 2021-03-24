module scope

import vash.util { auto_id }
import vash.types { TypeSymbol, unknown_type }

pub type ScopeObject = TypeSymbol | Var

pub struct Var {
pub:
	name string
	id   u64
pub mut:
	typ TypeSymbol
}

pub fn new_var(name string) Var {
	return Var{
		name: name
		typ: unknown_type
		id: auto_id()
	}
}

pub struct Scope {
pub:
	id u64
mut:
	parent   &Scope
	children []&Scope
	objects  map[string]ScopeObject
}

pub const global_id = 1

pub fn new_global_scope() &Scope {
	mut s := &Scope{
		id: scope.global_id
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
fn (mut s Scope) must_register(object ScopeObject) ScopeObject {
	return s.register(object) or { panic(err) }
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

pub fn (s &Scope) ident_for(object ScopeObject) string {
	return 's${s.id}_$object.name'
}
