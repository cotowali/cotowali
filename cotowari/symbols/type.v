module symbols

pub type Type = int

pub struct UnknownTypeInfo {}

pub struct PrimitiveTypeInfo {}

pub struct PlaceholderTypeInfo {
	is_fn bool
}

pub struct FunctionTypeInfo {
	args []Type
	ret  Type = builtin_type(.void)
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
