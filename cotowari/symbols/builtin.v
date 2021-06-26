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
	echo = 1
	call
	read
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
	ts_ := fn (k BuiltinTypeKey, info TypeInfo) TypeSymbol {
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

	t_ := builtin_type

	type_symbols := [
		placeholder_ts(.placeholder, {}),
		placeholder_ts(.placeholder_fn, is_function: true),
		ts_(.void, PrimitiveTypeInfo{}),
		ts_(.unknown, UnknownTypeInfo{}),
		ts_(.any, PrimitiveTypeInfo{}),
		ts_(.int, PrimitiveTypeInfo{}),
		ts_(.string, PrimitiveTypeInfo{}),
		ts_(.bool, PrimitiveTypeInfo{}),
	]
	mut array_types := map[int]Type{}
	mut reference_types := map[int]Type{}
	for ts in type_symbols {
		s.must_register_type(ts)
		typ := ts.typ
		if typ !in [t_(.placeholder), t_(.void), t_(.unknown)] {
			array_types[typ] = s.lookup_or_register_array_type(elem: typ).typ
			reference_types[typ] = s.lookup_or_register_reference_type(target: typ).typ
		}
	}

	f_ := fn (k BuiltinFnKey, fn_info FunctionTypeInfo) BuiltinFnInfo {
		return BuiltinFnInfo{k, fn_info}
	}

	fns := [
		f_(.echo, params: [t_(.any)], ret: t_(.string)),
		f_(.call,
			params: [t_(.string), array_types[t_(.string)]]
			is_varargs: true
			varargs_elem: t_(.string)
			ret: t_(.string)
		),
		f_(.seq, params: [t_(.int)], ret: array_types[t_(.int)]),
		f_(.read, params: [t_(.any)], ret: t_(.bool)),
	]
	for f in fns {
		s.must_register_builtin_fn(f.key, f.fn_info)
	}
}
