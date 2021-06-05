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
	return Type(u64(key))
}

pub enum BuiltinFnKey {
	echo = 0
	cat
	seq
}

pub fn builtin_fn_id(key BuiltinFnKey) u64 {
	return u64(key)
}

struct BuiltinFnInfo {
	key     BuiltinFnKey
	fn_info FunctionTypeInfo
}

fn (mut s Scope) must_register_builtin_fn(key BuiltinFnKey, info FunctionTypeInfo) &Var {
	typ := s.lookup_or_register_fn_type(info).typ
	return s.must_register_var(id: builtin_fn_id(key), name: key.str(), typ: typ)
}

pub fn (mut s Scope) register_builtin() {
	ts := fn (k BuiltinTypeKey, info TypeInfo) TypeSymbol {
		return TypeSymbol{
			typ: builtin_type(k)
			name: k.str()
			info: info
		}
	}
	placeholder_ts := fn (k BuiltinTypeKey, info PlaceholderTypeInfo) TypeSymbol {
		return TypeSymbol{
			typ: builtin_type(k)
			info: info
		}
	}

	t := fn (k BuiltinTypeKey) Type {
		return builtin_type(k)
	}

	type_symbols := [
		placeholder_ts(.placeholder, {}),
		placeholder_ts(.placeholder_fn, is_function: true),
		ts(.void, PrimitiveTypeInfo{}),
		ts(.unknown, UnknownTypeInfo{}),
		ts(.any, PrimitiveTypeInfo{}),
		ts(.int, PrimitiveTypeInfo{}),
		ts(.string, PrimitiveTypeInfo{}),
		ts(.bool, PrimitiveTypeInfo{}),
	]
	mut array_types := map[int]Type{}
	for ts_ in type_symbols {
		s.must_register_type(ts_)
		typ := ts_.typ
		if typ !in [t(.placeholder), t(.void), t(.unknown)] {
			array_types[typ] = s.lookup_or_register_array_type(elem: typ).typ
		}
	}

	f := fn (k BuiltinFnKey, fn_info FunctionTypeInfo) BuiltinFnInfo {
		return BuiltinFnInfo{k, fn_info}
	}

	fns := [
		f(.echo, params: [t(.any)], ret: t(.string)),
		f(.cat, params: [], ret: t(.string)),
		f(.seq, params: [t(.int)], ret: array_types[t(.int)]),
	]
	for f_ in fns {
		s.must_register_builtin_fn(f_.key, f_.fn_info)
	}
}
