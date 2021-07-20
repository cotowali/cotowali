// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

const unresolved_type_symbol = &TypeSymbol{
	typ: builtin_type(.placeholder)
	name: 'unresolved'
}

pub enum BuiltinTypeKey {
	placeholder = 0
	void
	any
	unknown
	int
	float
	string
	bool
}

pub fn builtin_type(key BuiltinTypeKey) Type {
	return Type(u64(key))
}

const number_types = [builtin_type(.int), builtin_type(.float)]

pub fn (t Type) is_number() bool {
	return t in symbols.number_types
}

pub enum BuiltinFnKey {
	echo = 1
	call
	read
}

pub fn builtin_fn_id(key BuiltinFnKey) u64 {
	return u64(key)
}

struct BuiltinFnInfo {
	key           BuiltinFnKey
	function_info FunctionTypeInfo
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

	t_ := builtin_type

	type_symbols := [
		*symbols.unresolved_type_symbol,
		ts_(.void, PrimitiveTypeInfo{}),
		ts_(.unknown, UnknownTypeInfo{}),
		ts_(.any, PrimitiveTypeInfo{}),
		ts_(.int, PrimitiveTypeInfo{}),
		ts_(.float, PrimitiveTypeInfo{}),
		ts_(.string, PrimitiveTypeInfo{}),
		ts_(.bool, PrimitiveTypeInfo{}),
	]
	mut array_types := map[int]Type{}
	mut variadic_types := map[int]Type{}
	mut reference_types := map[int]Type{}
	for ts in type_symbols {
		s.must_register_builtin_type(ts)
		typ := ts.typ
		if typ !in [t_(.placeholder), t_(.void), t_(.unknown)] {
			array_types[typ] = s.lookup_or_register_array_type(elem: typ).typ
			variadic_types[typ] = s.lookup_or_register_array_type(elem: typ, variadic: true).typ
			reference_types[typ] = s.lookup_or_register_reference_type(target: typ).typ
		}
	}

	f_ := fn (k BuiltinFnKey, function_info FunctionTypeInfo) BuiltinFnInfo {
		return BuiltinFnInfo{k, function_info}
	}

	fns := [
		f_(.echo, params: [t_(.any)], ret: t_(.string)),
		f_(.call, params: [t_(.string), variadic_types[t_(.string)]], ret: t_(.string)),
		f_(.read, params: [t_(.any)], ret: t_(.bool)),
	]
	for f in fns {
		s.must_register_builtin_fn(f.key, f.function_info)
	}
}
