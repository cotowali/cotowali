// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.messages { unreachable }
import strings

pub struct RegisterFnArgs {
	Var
	FunctionTypeInfo
}

pub struct FunctionTypeInfo {
pub:
	receiver Type = builtin_type(.placeholder)
	pipe_in  Type = builtin_type(.void)
	params   []Type
	variadic bool
	ret      Type = builtin_type(.void)
}

pub fn (ts TypeSymbol) function_info() ?FunctionTypeInfo {
	resolved := ts.resolved()
	return if resolved.info is FunctionTypeInfo { resolved.info } else { none }
}

pub fn (f &FunctionTypeInfo) is_method() bool {
	return f.receiver != builtin_type(.placeholder)
}

pub fn (f &FunctionTypeInfo) has_pipe_in() bool {
	return f.pipe_in != builtin_type(.void)
}

fn (f &FunctionTypeInfo) signature(s &Scope) string {
	mut sb := strings.new_builder(10)
	sb.write_string('fn ')
	if f.is_method() {
		sb.write_string('(${s.must_lookup_type(f.receiver).name}) ')
	}
	if f.has_pipe_in() {
		sb.write_string('${s.must_lookup_type(f.pipe_in).name} |> ')
	}
	sb.write_string('(' + f.params.map(s.must_lookup_type(it).name).join(', ') + ')')
	if f.ret != builtin_type(.void) {
		sb.write_string(if f.has_pipe_in() { ' |> ' } else { ': ' })
		sb.write_string(s.must_lookup_type(f.ret).name)
	}
	return sb.str()
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
