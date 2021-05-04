module symbols

type Symbol = TypeSymbol | Var

pub fn (v Symbol) scope() ?&Scope {
	if isnil(v.scope) {
		return none
	}
	return v.scope
}

pub fn (v Symbol) full_name() string {
	id := match v {
		Var { v.id }
		TypeSymbol { u64(v.typ) }
	}
	name := if v.name.len > 0 { v.name } else { 'sym$id' }
	if s := v.scope() {
		if s.is_global() {
			return name
		}
		return join_name(s.full_name(), name)
	} else {
		return name
	}
}

fn (v Symbol) scope_str() string {
	return if scope := v.scope() { scope.str() } else { 'none' }
}

// --- builtin --- //

pub enum BuiltinTypeKey {
	placeholder = 0
	unknown
	int
	string
	bool
}

pub struct Builtin {
pub:
	types        []Type
	type_symbols []TypeSymbol
}

pub fn builtin_type(key BuiltinTypeKey) Type {
	return Type(int(key))
}

pub const (
	builtin = (fn () Builtin {
		t := fn (k BuiltinTypeKey) Type {
			return builtin_type(k)
		}
		ts := fn (k BuiltinTypeKey, info TypeInfo) TypeSymbol {
			return TypeSymbol{
				typ: builtin_type(k)
				name: k.str()
				info: info
			}
		}
		types := [
			t(.placeholder),
			t(.unknown),
			t(.int),
			t(.string),
			t(.bool),
		]
		type_symbols := [
			ts(.unknown, UnknownTypeInfo{}),
			ts(.int, PrimitiveTypeInfo{}),
			ts(.string, PrimitiveTypeInfo{}),
			ts(.bool, PrimitiveTypeInfo{}),
		]
		return Builtin{types, type_symbols}
	}())
)
