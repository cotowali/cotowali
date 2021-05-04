module symbols

pub enum BuiltinTypeKey {
	placeholder = 0
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

	t := fn (k BuiltinTypeKey) Type {
		return builtin_type(k)
	}

	type_symbols := [
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
