module symbols

pub enum BuiltinTypeKey {
	placeholder = 0
	placeholder_fn
	void
	any
	unknown
	int
	string
	bool
}

pub fn builtin_type(key BuiltinTypeKey) Type {
	return Type(int(key))
}

pub fn (mut s Scope) register_builtin() {
	ts := fn (k BuiltinTypeKey, info TypeInfo) TypeSymbol {
		return TypeSymbol{
			typ: builtin_type(k)
			name: k.str()
			info: info
		}
	}
	ts_without_name := fn (k BuiltinTypeKey, info TypeInfo) TypeSymbol {
		return TypeSymbol{
			typ: builtin_type(k)
			info: info
		}
	}

	t := fn (k BuiltinTypeKey) Type {
		return builtin_type(k)
	}

	type_symbols := [
		ts_without_name(.placeholder, PlaceholderTypeInfo{}),
		ts_without_name(.placeholder_fn, PlaceholderTypeInfo{ is_function: true }),
		ts(.void, PrimitiveTypeInfo{}),
		ts(.unknown, UnknownTypeInfo{}),
		ts(.any, PrimitiveTypeInfo{}),
		ts(.int, PrimitiveTypeInfo{}),
		ts(.string, PrimitiveTypeInfo{}),
		ts(.bool, PrimitiveTypeInfo{}),
	]
	for typ in type_symbols {
		s.must_register_type(typ)
	}

	s.must_register_fn('echo', [t(.any)], t(.string))
}
