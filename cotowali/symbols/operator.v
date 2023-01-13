// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.token { Token, TokenKindClass }
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

fn verify_op_signature(expected TokenKindClass, op Token, fn_info FunctionTypeInfo) ? {
	expected_s := match expected {
		.infix_op { 'infix' }
		.prefix_op { 'prefix' }
		.postfix_op { 'postfix' }
		else { li_panic(@FN, @FILE, @LINE, 'not op kind') }
	} + ' operator'

	if !op.kind.@is(expected) {
		return error('`${op.text}` is not ${expected_s}')
	}

	subject := '${expected_s} function'
	check_number_of_parameters(subject, if expected == .infix_op { 2 } else { 1 }, fn_info.params.len)?
	check_no_variadic(subject, fn_info)?
	check_no_pipe_in(subject, fn_info)?
}

pub fn (mut s Scope) register_infix_op_function(op Token, f RegisterFnArgs) ?&Var {
	fn_info := f.FunctionTypeInfo
	verify_op_signature(.infix_op, op, fn_info)?

	lhs_ts := s.lookup_type(fn_info.params[0].typ)?
	rhs_ts := s.lookup_type(fn_info.params[1].typ)?

	fn_typ := s.lookup_or_register_function_type(fn_info).typ

	v := &Var{
		...f.Var
		id: if f.Var.id == 0 { auto_id() } else { f.Var.id }
		name: '${op.kind.str_for_ident()}' + lhs_ts.name + '_' + rhs_ts.name
		typ: fn_typ
		scope: s
	}

	if rhs_ts.typ in s.infix_op_functions[op.kind][lhs_ts.typ] {
		return error(already_defined(.operator, op.text))
	}
	s.infix_op_functions[op.kind][lhs_ts.typ][rhs_ts.typ] = v

	return v
}

fn (s &Scope) lookup_infix_op_function_strict(op Token, lhs Type, rhs Type) ?&Var {
	return s.infix_op_functions[op.kind][lhs][rhs] or {
		if p := s.parent() {
			return p.lookup_infix_op_function(op, lhs, rhs)
		}
		return none
	}
}

pub fn (s &Scope) lookup_infix_op_function(op Token, lhs Type, rhs Type) ?&Var {
	return s.lookup_infix_op_function_strict(op, lhs, rhs) or {
		// Since type may be defined by child, lookup_type may return none
		lhs_ts := s.lookup_type(lhs) or { return none }
		rhs_ts := s.lookup_type(rhs) or { return none }
		if lhs_alias_info := lhs_ts.alias_info() {
			if found := s.lookup_infix_op_function_strict(op, lhs_alias_info.target, rhs) {
				return found
			}
		}
		if rhs_alias_info := rhs_ts.alias_info() {
			if found := s.lookup_infix_op_function_strict(op, lhs, rhs_alias_info.target) {
				return found
			}
		}

		lhs_target := (lhs_ts.alias_info() or {
			AliasTypeInfo{
				target: lhs
			}
		}).target
		rhs_target := (rhs_ts.alias_info() or {
			AliasTypeInfo{
				target: lhs
			}
		}).target

		if lhs_target == lhs && rhs_target == rhs {
			return none
		}

		return s.lookup_infix_op_function(op, lhs_target, rhs_target)
	}
}

pub fn (mut s Scope) register_prefix_op_function(op Token, f RegisterFnArgs) ?&Var {
	fn_info := f.FunctionTypeInfo
	verify_op_signature(.prefix_op, op, fn_info)?

	operand_ts := s.lookup_type(fn_info.params[0].typ)?
	fn_typ := s.lookup_or_register_function_type(fn_info).typ

	v := &Var{
		...f.Var
		id: if f.Var.id == 0 { auto_id() } else { f.Var.id }
		name: '${op.kind.str_for_ident()}' + operand_ts.name
		typ: fn_typ
		scope: s
	}

	if operand_ts.typ in s.prefix_op_functions[op.kind] {
		return error(already_defined(.operator, op.text))
	}
	s.prefix_op_functions[op.kind][operand_ts.typ] = v

	return v
}

fn (s &Scope) lookup_prefix_op_function_strict(op Token, operand Type) ?&Var {
	return s.prefix_op_functions[op.kind][operand] or {
		if p := s.parent() {
			return p.lookup_prefix_op_function(op, operand)
		}
		return none
	}
}

pub fn (s &Scope) lookup_prefix_op_function(op Token, operand Type) ?&Var {
	return s.lookup_prefix_op_function_strict(op, operand) or {
		// Since type may be defined by child, lookup_type may return none
		operand_ts := s.lookup_type(operand) or { return none }
		if alias_info := operand_ts.alias_info() {
			return s.lookup_prefix_op_function(op, alias_info.target)
		}
		return none
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
