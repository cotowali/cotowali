module symbols

import cotowari.util { auto_id, nil_to_none }

pub struct Scope {
pub:
	id   u64
	name string
mut:
	parent       &Scope
	children     []&Scope
	vars         map[string]Var
	type_symbols map[int]TypeSymbol // map[Type]TypeSymbol
	name_to_type map[string]Type
}

pub fn (s &Scope) str() string {
	return s.full_name()
}

pub fn (s &Scope) debug_str() string {
	children_str := s.children.map(it.debug_str()).join('\n').split_into_lines().map('        $it').join('\n')
	vars_str := s.vars.keys().map("        '$it': ${s.vars[it]}").join('\n')
	types_str := s.type_symbols.keys().map('        ${s.type_symbols[it]}').join(',\n')
	return [
		'Scope{',
		'    id: $s.id',
		'    name: $s.name',
		'    children: [',
		children_str,
		'    ]',
		'    var: {',
		vars_str,
		'    }',
		'    types: [',
		types_str,
		'    ]',
		'}',
	].join('\n')
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
	s.register_builtin()
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

[inline]
pub fn (s &Scope) parent() ?&Scope {
	return nil_to_none(s.parent)
}

pub fn (s &Scope) children() []&Scope {
	return s.children
}

pub fn (mut s Scope) create_child(name string) &Scope {
	child := new_scope(name, s)
	s.children << child
	return child
}

pub fn (s &Scope) ident_for(v Var) string {
	if s.id == symbols.global_id {
		return v.name
	}
	return 's${s.id}_$v.name'
}
