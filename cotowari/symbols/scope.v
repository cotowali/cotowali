module symbols

import cotowari.util { auto_id }

pub struct Scope {
pub:
	id   u64
	name string
mut:
	parent       &Scope
	children     []&Scope
	symbols      map[string]Symbol
	type_symbols map[int]TypeSymbol // map[Type]TypeSymbol
}

pub fn (s &Scope) str() string {
	return s.full_name()
}

pub fn (s &Scope) debug_str() string {
	children_str := s.children.map(it.debug_str()).join('\n').split_into_lines().map('        $it').join('\n')
	syms_str := s.symbols.keys().map("        '$it': ${s.symbols[it]}").join('\n')
	types_str := s.type_symbols.keys().map('        ${s.type_symbols[it]}').join(',\n')
	return [
		'Scope{',
		'    id: $s.id',
		'    name: $s.name',
		'    children: [',
		children_str,
		'    ]',
		'    symbols: {',
		syms_str,
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
}

pub fn (mut s Scope) register_type(ts TypeSymbol) ?TypeSymbol {
	s.check_before_register_type(ts) ?
	typ := if ts.typ == 0 { Type(int(auto_id())) } else { ts.typ }
	new_ts := TypeSymbol{
		...ts
		typ: typ
	}
	s.type_symbols[int(typ)] = new_ts
	return new_ts
}

[inline]
fn (mut s Scope) must_register_type(ts TypeSymbol) TypeSymbol {
	return s.register_type(ts) or { panic(err) }
}

pub fn (s &Scope) lookup_type(typ Type) ?TypeSymbol {
	key := int(typ)
	if key in s.type_symbols {
		return s.type_symbols[key]
	}
	if p := s.parent() {
		return p.lookup_type(typ)
	}
	return none
}

pub fn (s &Scope) must_lookup_type(typ Type) TypeSymbol {
	return s.lookup_type(typ) or { panic(err) }
}

pub fn (mut s Scope) lookup_or_register_type(ts TypeSymbol) TypeSymbol {
	return s.lookup_type(ts.typ) or { s.register_type(ts) or { panic(err) } }
}

pub fn (s &Scope) ident_for(sym Symbol) string {
	if s.id == symbols.global_id {
		return sym.name
	}
	return 's${s.id}_$sym.name'
}
