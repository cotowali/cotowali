// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

fn test_signature() ? {
	mut s := new_global_scope()
	f1 := s.register_type(
		name: 'f1'
		info: FunctionTypeInfo{
			params: [builtin_type(.int), builtin_type(.bool)]
		}
	) ?
	f2 := s.register_type(
		name: 'f2'
		info: FunctionTypeInfo{
			params: [builtin_type(.int), builtin_type(.bool)]
			ret: builtin_type(.int)
		}
	) ?
	f3 := s.register_type(
		name: 'f3'
		info: FunctionTypeInfo{
			pipe_in: builtin_type(.int)
			params: [builtin_type(.int), builtin_type(.bool)]
			ret: builtin_type(.int)
		}
	) ?
	f4 := s.register_type(
		name: 'f4'
		info: FunctionTypeInfo{
			pipe_in: builtin_type(.int)
			params: [builtin_type(.int), s.must_lookup_array_type(elem: builtin_type(.int)).typ]
			variadic: true
			ret: builtin_type(.int)
		}
	) ?
	f5 := s.register_type(
		name: 'f5'
		info: FunctionTypeInfo{
			is_test: true
		}
	) ?

	assert f1.signature() ? == 'fn (int, bool)'
	assert f2.signature() ? == 'fn (int, bool): int'
	assert f3.signature() ? == 'fn int |> (int, bool) |> int'
	assert f4.signature() ? == 'fn int |> (int, ...int) |> int'
	assert f5.signature() ? == '#[test] fn ()'
	if _ := s.must_lookup_type(builtin_type(.int)).signature() {
		assert false
	}
}

fn test_lookup_type_and_register_type() ? {
	mut parent := new_global_scope()
	mut child := parent.must_create_child('child')

	name_t := 't'

	parent_t := parent.register_type(name: 't') ?
	mut found := parent.must_lookup_type(parent_t.typ)
	assert found.typ == parent_t.typ
	found = parent.must_lookup_type(parent_t.name)
	assert found.typ == parent_t.typ
	found = child.must_lookup_type(parent_t.typ)
	assert found.typ == parent_t.typ
	found = child.must_lookup_type(parent_t.name)
	assert found.typ == parent_t.typ

	child_t := child.register_type(name: 't') ?
	if _ := parent.lookup_type(child_t.typ) {
		assert false
	}
	found = child.must_lookup_type(child_t.typ)
	assert found.typ != parent_t.typ
	assert found.typ == child_t.typ
	found = child.must_lookup_type(child_t.name)
	assert found.typ != parent_t.typ
	assert found.typ == child_t.typ

	if _ := child.lookup_type(Type(99999)) {
		assert false
	}
	if _ := child.register_type(name: child_t.name) {
		assert false
	}
}

fn test_lookup_or_register_type() ? {
	mut s := new_global_scope()
	ts_n := s.type_symbols.keys().len
	registered := s.lookup_or_register_type(name: 't')
	assert (registered.scope() ?).id == s.id
	assert registered.typ != Type(0)
	assert s.type_symbols.keys().len == ts_n + 1

	mut found := s.lookup_or_register_type(typ: registered.typ)
	assert registered.typ == found.typ
	assert s.type_symbols.keys().len == ts_n + 1

	found = s.lookup_or_register_type(name: registered.name)
	assert registered.typ == found.typ
	assert s.type_symbols.keys().len == ts_n + 1
}

fn test_is_number() ? {
	int_t := builtin_type(.int)

	assert int_t.is_number()
	assert builtin_type(.float).is_number()

	assert !builtin_type(.string).is_number()

	mut s := new_global_scope()
	int_int := s.lookup_or_register_tuple_type(elements: [int_t, int_t].map(TupleElement{ typ: it }))
	assert !int_int.typ.is_number()
	assert (int_int.tuple_info() ?).elements[0].typ.is_number()

	int_arr := s.lookup_or_register_array_type(elem: int_t)
	assert !int_arr.typ.is_number()
	assert (int_arr.array_info() ?).elem.is_number()
}

fn test_struct_type() ? {
	mut s := new_global_scope()
	ts := s.register_struct_type('',
		fields: {
			'n': builtin_type(.int)
			's': builtin_type(.string)
		}
	) ?
	if struct_info := ts.struct_info() {
		assert struct_info.type_to_str(s) == 'struct { n int, s string }'
	} else {
		assert false
	}
}

fn test_resolved() ? {
	mut s := new_global_scope()
	int_ := builtin_type(.int)
	int2_ts := s.register_alias_type(name: 'int2', target: int_) ?
	int3_ts := s.register_alias_type(name: 'int3', target: int2_ts.typ) ?
	assert int2_ts.resolved().typ == int_
	assert int3_ts.resolved().typ == int_
	assert s.must_lookup_type(int_).resolved().typ == int_
}

fn test_method() ? {
	mut s := new_global_scope()
	int_ := builtin_type(.int)

	mut base := (s.register_type(name: 'Base') ?)
	mut t1 := (s.register_type(name: 'Type1', base: base) ?)
	mut t2 := (s.register_type(name: 'Type2') ?)

	if _ := t1.lookup_method('f') {
		assert false
	}

	base_method1 := base.register_method(name: 'f', params: [], ret: int_) ?
	assert base_method1.id != 0
	if found := t1.lookup_method(base_method1.name) {
		assert found.id == base_method1.id
	} else {
		assert false
	}

	method1 := t1.register_method(name: base_method1.name, params: [int_], ret: int_) ?
	if _ := t1.register_method(name: method1.name, params: [int_], ret: int_) {
		assert false
	}
	assert method1.id != 0
	if found := t1.lookup_method(base_method1.name) {
		assert found.id == method1.id
		assert found.id != base_method1.id
	} else {
		assert false
	}

	// same name, different receiver
	method2 := t2.register_method(
		name: 'f'
		pipe_in: int_
		params: [
			int_,
		]
	) ?
	assert method1.name == method2.name
	assert method2.id != 0
	assert method1.id != method2.id
	if found := t2.lookup_method(method2.name) {
		assert found.id == method2.id
	} else {
		assert false
	}

	assert (method2.type_symbol().signature() ?) == 'fn (Type2) int |> (int)'
}
