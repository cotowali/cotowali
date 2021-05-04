module symbols

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
