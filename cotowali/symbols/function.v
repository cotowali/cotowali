// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import strings
import cotowali.util { li_panic }

pub struct RegisterFnArgs {
	Var
	FunctionTypeInfo
}

pub struct FunctionTypeInfo {
mut:
	min_params_count int = -1
pub:
	receiver Type = builtin_type(.placeholder)
	pipe_in  Type = builtin_type(.void)
	params   []FunctionParam
	variadic bool
	is_test  bool
	ret      Type = builtin_type(.void)
}

pub struct FunctionParam {
pub:
	name        string
	typ         Type
	has_default bool
}

pub fn (ts TypeSymbol) function_info() ?FunctionTypeInfo {
	resolved := ts.resolved()
	return if resolved.info is FunctionTypeInfo { resolved.info } else { none }
}

pub fn (f &FunctionTypeInfo) min_params_count() int {
	if f.min_params_count >= 0 {
		return f.min_params_count
	}
	for i, param in f.params {
		if param.has_default {
			unsafe {
				f.min_params_count = i
			}
			return f.min_params_count
		}
	}
	unsafe {
		f.min_params_count = if f.variadic { f.params.len - 1 } else { f.params.len }
	}
	return f.min_params_count
}

pub fn (f &FunctionTypeInfo) is_method() bool {
	return f.receiver != builtin_type(.placeholder)
}

pub fn (f &FunctionTypeInfo) has_pipe_in() bool {
	return f.pipe_in != builtin_type(.void)
}

fn (f &FunctionTypeInfo) signature(s &Scope) string {
	mut sb := strings.new_builder(10)
	if f.is_test {
		sb.write_string('#[test] ')
	}
	sb.write_string('fn ')
	if f.is_method() {
		sb.write_string('(${s.must_lookup_type(f.receiver).name}) ')
	}
	if f.has_pipe_in() {
		sb.write_string('${s.must_lookup_type(f.pipe_in).name} |> ')
	}

	sb.write_string('(')
	for i, param in f.params {
		ts := s.must_lookup_type(param.typ)
		if i == f.params.len - 1 && f.variadic {
			array := ts.array_info() or { li_panic(@FN, @FILE, @LINE, '') }
			sb.write_string('...${s.must_lookup_type(array.elem).name}')
		} else {
			sb.write_string('$ts.name')
			if param.has_default {
				sb.write_string(' ? ')
			}
		}
		if i < f.params.len - 1 {
			sb.write_string(', ')
		}
	}
	sb.write_string(')')

	if f.ret != builtin_type(.void) {
		sb.write_string(if f.has_pipe_in() { ' |> ' } else { ': ' })
		sb.write_string(s.must_lookup_type(f.ret).name)
	}
	return sb.str()
}

pub fn (t TypeSymbol) signature() ?string {
	return if t.info is FunctionTypeInfo { t.info.signature(t.scope() or {
			li_panic(@FN, @FILE, @LINE, err)}) } else { none }
}

pub fn (mut s Scope) lookup_or_register_function_type(info FunctionTypeInfo) &TypeSymbol {
	typename := info.signature(s)
	return s.lookup_or_register_type(name: typename, info: info)
}

pub fn (s Scope) lookup_function_type(info FunctionTypeInfo) ?&TypeSymbol {
	typename := info.signature(s)
	return s.lookup_type(typename)
}

pub fn (s &Scope) lookup_function(name string) ?&Var {
	v := s.lookup_var(name)?
	return if v.is_function() { v } else { none }
}

pub fn (mut s Scope) register_function(f RegisterFnArgs) ?&Var {
	typ := s.lookup_or_register_function_type(f.FunctionTypeInfo).typ
	return s.register_var(Var{ ...f.Var, typ: typ })
}

fn (mut s Scope) must_register_function(f RegisterFnArgs) &Var {
	return s.register_function(f) or { li_panic(@FN, @FILE, @LINE, err) }
}
