// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module checker

import cotowali.ast { Expr }
import cotowali.symbols { ArrayTypeInfo, TypeSymbol, builtin_type }
import cotowali.messages { args_count_mismatch }

fn (mut c Checker) nameof(expr ast.Nameof) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	if expr.args.len != 1 {
		c.error(args_count_mismatch(expected: 1, actual: expr.args.len), expr.pos())
		return
	}
	arg := expr.args[0]
	match arg {
		ast.Var, ast.ModuleItem {}
		else { c.error('expression does not have a name', arg.pos()) }
	}
}

fn (mut c Checker) typeof_(expr ast.Typeof) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	if expr.args.len != 1 {
		c.error(args_count_mismatch(expected: 1, actual: expr.args.len), expr.pos())
		return
	}

	c.expr(expr.args[0])
}

fn (mut c Checker) fn_decl(stmt ast.FnDecl) {
	$if trace_checker ? {
		c.trace_begin(@FN, stmt.sym.name, stmt.signature())
		defer {
			c.trace_end()
		}
	}

	old_fn := c.current_fn
	c.current_fn = &stmt
	defer {
		c.current_fn = old_fn
	}

	fn_info := stmt.function_info()

	if stmt.is_test() {
		if fn_info.has_pipe_in() {
			c.error('test function cannot have pipe-in', stmt.sym.pos)
		}
		if stmt.params.len != 0 {
			pos := stmt.params[0].pos().merge(stmt.params.last().pos())
			c.error('test function cannot have parameters', pos)
		}
		if fn_info.ret != builtin_type(.void) {
			c.error('test function cannot have return values', stmt.sym.pos)
		}
	}

	if pipe_in_param := stmt.pipe_in_param() {
		pipe_in_param_ts := Expr(pipe_in_param).type_symbol()
		if _ := pipe_in_param_ts.sequence_info() {
			pos := pipe_in_param.pos().merge(pipe_in_param_ts.pos)
			c.error('sequence type cannot be used for pipe-in parameter', pos)
		}
	}

	c.attrs(stmt.attrs)
	c.exprs(stmt.params.map(Expr(it)))
	c.block(stmt.body)
}

fn (mut c Checker) call_command_expr(expr ast.CallCommandExpr) {
	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	c.exprs(expr.args)
}

fn (mut c Checker) call_expr(expr ast.CallExpr) {
	if Expr(expr).typ() == builtin_type(.placeholder) {
		return
	}

	$if trace_checker ? {
		c.trace_begin(@FN)
		defer {
			c.trace_end()
		}
	}

	pos := Expr(expr).pos()
	scope := expr.scope
	function_info := expr.function_info()
	params := function_info.params
	param_syms := params.map(scope.must_lookup_type(it))
	args := expr.args

	if function_info.is_test {
		c.error('cannot explicitly call test function', pos)
	}

	if function_info.variadic {
		min_len := params.len - 1
		if args.len < min_len {
			c.error(args_count_mismatch(expected: '$min_len or more', actual: args.len),
				pos)
			return
		}
	} else if args.len != params.len {
		c.error(args_count_mismatch(expected: params.len, actual: args.len), pos)
		return
	}

	c.exprs(args)

	mut call_args_types_ok := true
	varargs_elem_ts := if function_info.variadic {
		scope.must_lookup_type((param_syms.last().info as ArrayTypeInfo).elem)
	} else {
		// ?TypeSymbol(none)
		&TypeSymbol{}
	}
	for i, arg in args {
		arg_ts := arg.type_symbol()
		param_ts := if function_info.variadic && i >= params.len - 1 {
			if arg.is_glob_literal() && varargs_elem_ts.typ == builtin_type(.string) {
				// allow glob literal as string varargs
				continue
			}

			varargs_elem_ts
		} else {
			scope.must_lookup_type(params[i])
		}

		if param_ts.kind() == .placeholder || arg_ts.kind() == .placeholder {
			call_args_types_ok = false
			continue
		}

		c.check_types(want: param_ts, got: arg_ts, pos: arg.pos()) or { call_args_types_ok = false }
	}
	if !call_args_types_ok {
		return
	}
}
