module symbols

// --- Var --- //

pub struct Var {
mut:
	scope &Scope = 0
pub:
	name string
	id   u64
pub mut:
	typ Type = builtin_type(.placeholder)
}

pub fn (v Var) str() string {
	return 'Var{ name: $v.name, scope: $v.scope_str(), typ: $v.typ }'
}

pub fn (v Var) scope() ?&Scope {
	if isnil(v.scope) {
		return none
	}
	return v.scope
}

fn (v Var) scope_str() string {
	return if scope := v.scope() { scope.str() } else { 'none' }
}

pub fn (v Var) full_name() string {
	name := if v.name.len > 0 { v.name } else { 'v$v.id' }
	if s := v.scope() {
		if s.is_global() {
			return name
		}
		return join_name(s.full_name(), name)
	} else {
		return name
	}
}

pub fn (v Var) type_symbol() TypeSymbol {
	if scope := v.scope() {
		return scope.lookup_type(v.typ) or { symbols.unresolved_type_symbol }
	}
	return symbols.unresolved_type_symbol
}

// --- Type --- //

pub type Type = int

pub struct UnknownTypeInfo {}

pub struct PrimitiveTypeInfo {}

pub struct PlaceholderTypeInfo {
	is_fn bool
}

pub struct FunctionTypeInfo {
	args []Type
	ret  Type
}

pub type TypeInfo = FunctionTypeInfo | PlaceholderTypeInfo | PrimitiveTypeInfo | UnknownTypeInfo

pub struct TypeSymbol {
mut:
	scope &Scope = 0
pub:
	typ  Type
	name string
	info TypeInfo = TypeInfo(PlaceholderTypeInfo{})
}

const unresolved_type_symbol = TypeSymbol{
	typ: Type(-1)
	name: 'unresolved'
	info: PlaceholderTypeInfo{}
}

pub fn (t TypeSymbol) scope() ?&Scope {
	if isnil(t.scope) {
		return none
	}
	return t.scope
}

pub fn (t TypeSymbol) is_fn() bool {
	info := t.info
	return match info {
		PlaceholderTypeInfo { info.is_fn }
		FunctionTypeInfo { true }
		else { false }
	}
}

pub enum TypeKind {
	placeholder
	unknown
	primitive
	func
}

// type kind
[inline]
fn tk(k TypeKind) TypeKind {
	return k
}

pub fn (t TypeSymbol) kind() TypeKind {
	return match t.info {
		UnknownTypeInfo { tk(.unknown) }
		PlaceholderTypeInfo { tk(.placeholder) }
		PrimitiveTypeInfo { tk(.primitive) }
		FunctionTypeInfo { tk(.func) }
	}
}

pub fn (v TypeSymbol) str() string {
	return 'TypeSymbol{ typ: $v.typ, name: $v.name, kind: $v.kind().str() }'
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
