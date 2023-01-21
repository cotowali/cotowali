// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.messages { already_defined }
import cotowali.util { li_panic }

fn check_no_variadic(subject string, fn_info FunctionTypeInfo) ? {
	if fn_info.variadic {
		return error('${subject} cannot be variadic')
	}
}

fn check_no_pipe_in(subject string, fn_info FunctionTypeInfo) ? {
	if fn_info.pipe_in != builtin_type(.void) {
		return error('${subject} cannot have pipe in')
	}
}

fn check_number_of_parameters(subject string, expected int, actual int) ? {
	if actual != expected {
		expected_params := if expected == 1 { '1 parameter' } else { '${expected} parameters' }
		return error('${subject} must have ${expected_params}')
	}
}

[params]
pub struct CastFunctionParams {
	from Type = builtin_type(.placeholder)
	to   Type = builtin_type(.placeholder)
}

pub fn (mut s Scope) register_cast_function(f RegisterFnArgs, params CastFunctionParams) ?&Var {
	fn_info := f.FunctionTypeInfo

	subject := 'cast function'
	check_number_of_parameters(subject, 0, fn_info.params.len - 1)?
	check_no_variadic(subject, fn_info)?
	check_no_pipe_in(subject, fn_info)?

	$if !prod {
		if params.from != builtin_type(.placeholder) && params.from != fn_info.params[0].typ {
			li_panic(@FN, @FILE, @LINE, 'mismatch from.typ and params[0]')
		}
		if params.to != builtin_type(.placeholder) && params.to != fn_info.ret {
			li_panic(@FN, @FILE, @LINE, 'mismatch to.typ and ret')
		}
	}

	from, to := s.must_lookup_type(fn_info.params[0].typ), s.must_lookup_type(fn_info.ret)

	if to.typ == builtin_type(.void) {
		return error('${subject} must have return values')
	}

	fn_typ := s.lookup_or_register_function_type(fn_info).typ

	v := &Var{
		...f.Var
		id: if f.Var.id == 0 { auto_id() } else { f.Var.id }
		name: from.name + '_as_' + to.name
		typ: fn_typ
		scope: s
	}

	if to.typ in s.cast_functions[from.typ] {
		return error(already_defined(.operator, '${from.name} as ${to.name}'))
	}
	s.cast_functions[from.typ][to.typ] = v

	return v
}

pub fn (s &Scope) lookup_cast_function(params CastFunctionParams) ?&Var {
	return s.cast_functions[params.from][params.to] or {
		if p := s.parent() {
			return p.lookup_cast_function(params)
		}
		return none
	}
}
