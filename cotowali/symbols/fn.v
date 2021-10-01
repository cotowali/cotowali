// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.messages { unreachable }

pub struct RegisterFnArgs {
	Var
	FunctionTypeInfo
}

pub struct FunctionTypeInfo {
pub:
	receiver Type = builtin_type(.placeholder)
	pipe_in  Type = builtin_type(.void)
	params   []Type
	ret      Type = builtin_type(.void)
}

pub fn (ts TypeSymbol) function_info() ?FunctionTypeInfo {
	resolved := ts.resolved()
	return if resolved.info is FunctionTypeInfo { resolved.info } else { none }
}

pub fn (f &FunctionTypeInfo) is_method() bool {
	return f.receiver != builtin_type(.placeholder)
}

fn (f &FunctionTypeInfo) signature(s &Scope) string {
	params_str := f.params.map(s.must_lookup_type(it).name).join(', ')
	in_str := s.must_lookup_type(f.pipe_in).name
	ret_str := s.must_lookup_type(f.ret).name

	return (if f.is_method() {
		'fn (${s.must_lookup_type(f.receiver).name})'
	} else {
		'fn'
	}) + ' $in_str | ($params_str) $ret_str'
}

pub fn (t TypeSymbol) fn_signature() ?string {
	return if t.info is FunctionTypeInfo {
		t.info.signature(t.scope() or { panic(unreachable(err)) })
	} else {
		none
	}
}

pub fn (mut s Scope) lookup_or_register_fn_type(info FunctionTypeInfo) &TypeSymbol {
	typename := info.signature(s)
	return s.lookup_or_register_type(name: typename, info: info)
}

pub fn (s Scope) lookup_fn_type(info FunctionTypeInfo) ?&TypeSymbol {
	typename := info.signature(s)
	return s.lookup_type(typename)
}

pub fn (s &Scope) lookup_fn(name string) ?&Var {
	v := s.lookup_var(name) ?
	return if v.is_function() { v } else { none }
}

pub fn (mut s Scope) register_fn(f RegisterFnArgs) ?&Var {
	typ := s.lookup_or_register_fn_type(f.FunctionTypeInfo).typ
	return s.register_var(Var{ ...f.Var, typ: typ })
}

fn (mut s Scope) must_register_fn(f RegisterFnArgs) &Var {
	return s.register_fn(f) or { panic(unreachable(err)) }
}
