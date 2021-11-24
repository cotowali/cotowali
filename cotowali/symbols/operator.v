// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.token { Token, TokenKindClass }
import cotowali.messages { already_defined, unreachable }

fn verify_op_signature(expected TokenKindClass, op Token, fn_info FunctionTypeInfo) ? {
	expected_s := match expected {
		.infix_op { 'infix' }
		.prefix_op { 'prefix' }
		.postfix_op { 'postfix' }
		else { panic(unreachable('not op kind')) }
	} + ' operator'

	if !op.kind.@is(expected) {
		return error('`$op.text` is not $expected_s')
	}

	subject := '$expected_s function'
	params_n := if expected == .infix_op { 2 } else { 1 }
	if fn_info.params.len != params_n {
		expected_params := if params_n == 1 { '1 parameter' } else { '$params_n parameters' }
		return error('$subject must have $expected_params')
	}

	if fn_info.variadic {
		return error('$subject cannot be variadic')
	}

	if fn_info.pipe_in != builtin_type(.void) {
		return error('$subject cannot have pipe in')
	}
}

pub fn (mut s Scope) register_infix_op_function(op Token, f RegisterFnArgs) ?&Var {
	fn_info := f.FunctionTypeInfo
	verify_op_signature(.infix_op, op, fn_info) ?

	lhs_ts := s.lookup_type(fn_info.params[0]) ?
	rhs_ts := s.lookup_type(fn_info.params[1]) ?

	fn_typ := s.lookup_or_register_function_type(fn_info).typ

	v := &Var{
		...f.Var
		id: if f.Var.id == 0 { auto_id() } else { f.Var.id }
		name: '$op.kind.str_for_ident()' + lhs_ts.name + '_' + rhs_ts.name
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
	verify_op_signature(.prefix_op, op, fn_info) ?

	operand_ts := s.lookup_type(fn_info.params[0]) ?
	fn_typ := s.lookup_or_register_function_type(fn_info).typ

	v := &Var{
		...f.Var
		id: if f.Var.id == 0 { auto_id() } else { f.Var.id }
		name: '$op.kind.str_for_ident()' + operand_ts.name
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
