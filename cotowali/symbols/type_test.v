// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

fn test_fn_signature() ? {
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
			pipe_in: builtin_type(.int)
			params: [builtin_type(.int), builtin_type(.bool)]
			ret: builtin_type(.int)
		}
	) ?
	assert f1.fn_signature() ? == 'fn void | (int, bool) void'
	assert f2.fn_signature() ? == 'fn int | (int, bool) int'
	if _ := s.must_lookup_type(builtin_type(.int)).fn_signature() {
		assert false
	}
}

fn test_lookup_type_and_register_type() ? {
	mut parent := new_global_scope()
	mut child := parent.create_child('child')

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
	if _ := child.register_type(typ: child_t.typ) {
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
