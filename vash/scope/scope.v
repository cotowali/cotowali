module scope

pub struct Scope {
mut:
	parent &Scope
	children []&Scope
}

pub fn new_scope() &Scope {
	return &Scope {
		parent: 0
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
	child := &Scope{ parent: s }
	s.children << child
	return child
}
