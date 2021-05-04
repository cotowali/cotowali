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

pub fn (v TypeSymbol) scope() ?&Scope {
	return Symbol(v).scope()
}

fn (v TypeSymbol) scope_str() string {
	return Symbol(v).scope_str()
}

pub fn (v TypeSymbol) full_name() string {
	return Symbol(v).full_name()
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
