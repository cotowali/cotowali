// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module symbols

import cotowali.token { Token }
import cotowali.messages {
	OpNotation,
	already_defined,
	invalid_operator_kind,
	invalid_operator_signature,
}

fn verify_op_fn_signature(op OpNotation, fn_info FunctionTypeInfo) ? {
	params_n := if op == .infix { 2 } else { 1 }
	if fn_info.params.len != params_n {
		return error(invalid_operator_signature(.parameters_count, op))
	}
	if fn_info.variadic {
		return error(invalid_operator_signature(.variadic, op))
	}
	if fn_info.pipe_in != builtin_type(.void) {
		return error(invalid_operator_signature(.have_pipe_in, op))
	}
}

pub fn (mut s Scope) register_infix_op(op Token, f RegisterFnArgs) ?&Var {
	if !op.kind.@is(.infix_op) {
		return error(invalid_operator_kind(.infix, op.text))
	}

	fn_info := f.FunctionTypeInfo
	verify_op_fn_signature(.infix, fn_info) ?

	lhs_ts := s.lookup_type(fn_info.params[0]) ?
	rhs_ts := s.lookup_type(fn_info.params[1]) ?

	fn_typ := s.lookup_or_register_fn_type(fn_info).typ

	v := &Var{
		...f.Var
		id: if f.Var.id == 0 { auto_id() } else { f.Var.id }
		name: '$op.kind.str_for_ident()' + lhs_ts.name + '_' + rhs_ts.name
		typ: fn_typ
		scope: s
	}

	if rhs_ts.typ in s.infix_op_fns[op.kind][lhs_ts.typ] {
		return error(already_defined(.operator, op.text))
	}
	s.infix_op_fns[op.kind][lhs_ts.typ][rhs_ts.typ] = v

	return v
}

pub fn (s &Scope) lookup_infix_op(op Token, lhs Type, rhs Type) ?&Var {
	return s.infix_op_fns[op.kind][lhs][rhs] or {
		if p := s.parent() {
			return p.lookup_infix_op(op, lhs, rhs)
		}
		return none
	}
}
