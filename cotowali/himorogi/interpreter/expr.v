// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module interpreter

import cotowali.ast { Expr }
import cotowali.symbols { builtin_type }
import cotowali.util { li_panic }

fn (mut e Interpreter) expr(expr Expr) Value {
	return match expr {
		ast.AsExpr { e.as_expr(expr) }
		ast.BoolLiteral { e.bool_literal(expr) }
		ast.CallCommandExpr { e.call_command_expr(expr) }
		ast.CallExpr { e.call_expr(expr) }
		ast.DefaultValue { e.default_value(expr) }
		ast.DecomposeExpr { e.decompose_expr(expr) }
		ast.Empty { Value('') }
		ast.FloatLiteral { e.float_literal(expr) }
		ast.IntLiteral { e.int_literal(expr) }
		ast.ParenExpr { e.paren_expr(expr) }
		ast.Pipeline { e.pipeline(expr) }
		ast.InfixExpr { e.infix_expr(expr) }
		ast.IndexExpr { e.index_expr(expr) }
		ast.MapLiteral { e.map_literal(expr) }
		ast.ModuleItem { e.module_item(expr) }
		ast.NullLiteral { e.null_literal(expr) }
		ast.PrefixExpr { e.prefix_expr(expr) }
		ast.SelectorExpr { e.selector_expr(expr) }
		ast.Nameof { Value(expr.value()) }
		ast.Typeof { Value(expr.value()) }
		ast.ArrayLiteral { e.array_literal(expr) }
		ast.StringLiteral { e.string_literal(expr) }
		ast.Var { e.var_(expr) }
	}
}

fn (mut e Interpreter) as_expr(expr ast.AsExpr) Value {
	todo(@FN, @FILE, @LINE)
	/*
	if call_expr := expr.overloaded_function_call_expr() {
		e.call_expr(call_expr, opt)
		return
	}
	e.expr(expr.expr, paren: true)
	*/
}

fn (mut e Interpreter) decompose_expr(expr ast.DecomposeExpr) Value {
	// any decompose expr handled in other places (e.g. paren_expr)
	li_panic(@FN, @FILE, @LINE, 'invalid decompose')
}

fn (mut e Interpreter) default_value(expr ast.DefaultValue) Value {
	ts := Expr(expr).type_symbol()
	ts_resolved := ts.resolved()

	if tuple_info := ts_resolved.tuple_info() {
		return e.paren_expr(ast.ParenExpr{
			scope: expr.scope
			exprs: tuple_info.elements.map(Expr(ast.DefaultValue{
				typ: it.typ
				scope: expr.scope
			}))
		})
	}

	if ts_resolved.kind() == .array {
		return []Value{}
	}

	return match ts_resolved.typ {
		builtin_type(.bool) { Value(false) }
		builtin_type(.int) { Value(i64(0)) }
		builtin_type(.float) { Value(f64(0)) }
		else { Value('') }
	}
}

fn (mut e Interpreter) index_expr(expr ast.IndexExpr) Value {
	todo(@FN, @FILE, @LINE)
	/*
	left := e.expr(expr.left)
	index := e.expr(expr.index)
	*/
}

fn (mut e Interpreter) infix_expr(expr ast.InfixExpr) Value {
	op := expr.op
	if !op.kind.@is(.infix_op) {
		li_panic(@FN, @FILE, @LINE, 'not a infix op')
	}

	if call_expr := expr.overloaded_function_call_expr() {
		return e.call_expr(call_expr)
	}

	if op.kind == .pow {
		todo(@FN, @FILE, @LINE)
	}

	lhs, rhs := promote(e.expr(expr.left), e.expr(expr.right))
	return match op.kind {
		.eq { Value(lhs == rhs) }
		.ne { Value(lhs != rhs) }
		/*
		.lt { Value(lhs < rhs) }
		.le { Value(lhs <= rhs) }
		.gt { Value(lhs > rhs) }
		.ge { Value(lhs >= rhs) }
		.logical_and { Value(lhs.bool() && rhs.bool()) }
		.logical_or { Value(lhs.bool() || rhs.bool()) }
		*/
		.plus { lhs.add(rhs) }
		.minus { lhs.sub(rhs) }
		/*
		.mul { lhs * rhs }
		.div { lhs / rhs }
		.mod { lhs % rhs }
		*/
		else { todo(@FN, @FILE, @LINE) }
	}
}

fn (mut e Interpreter) module_item(expr ast.ModuleItem) Value {
	if !expr.is_resolved() {
		li_panic(@FN, @FILE, @LINE, 'unresolved module item')
	}
	return e.expr(expr.item)
}

fn (mut e Interpreter) paren_expr(expr ast.ParenExpr) Value {
	todo(@FN, @FILE, @LINE)
	/*
	if expr.exprs.len == 0 {
		e.write('@()')
		return
	}
	if expr.exprs.len > 0 && expr.exprs[0] !is ast.DecomposeExpr {
		e.write('(')
	}
	for i, subexpr in expr.exprs {
		if subexpr is ast.DecomposeExpr {
			if i > 0 {
				if expr.exprs[i - 1] !is ast.DecomposeExpr {
					e.write(')')
				}
				e.write(' + ')
			}
			e.expr(subexpr.expr, paren: true)
			if expr.exprs.len > 1 && i < expr.exprs.len - 1 {
				if expr.exprs[i + 1] !is ast.DecomposeExpr {
					e.write('+ @(')
				}
			}
			continue
		}
		if i > 0 {
			e.write(', ')
		}
		e.expr(subexpr, paren: true)
	}
	if expr.exprs.len > 0 && expr.exprs.last() !is ast.DecomposeExpr {
		e.write(')')
	}
	*/
}

fn (mut e Interpreter) prefix_expr(expr ast.PrefixExpr) Value {
	op := expr.op
	if !op.kind.@is(.prefix_op) {
		li_panic(@FN, @FILE, @LINE, 'not a prefix op')
	}

	if call_expr := expr.overloaded_function_call_expr() {
		return e.call_expr(call_expr)
	}

	todo(@FN, @FILE, @LINE)
	/*
	if op.kind == .amp {
		todo(@FN, @FILE, @LINE)
	}

	value := e.expr(expr.expr)
	return match op.kind {
		.not { value.not() }
		.plus { value }
		.minus { value * Value(-1) }
		else { li_panic(@FN, @FILE, @LINE, 'invalid op $op.text') }
	}
	*/
}

fn (mut e Interpreter) pipeline(pipeline ast.Pipeline) Value {
	todo(@FN, @FILE, @LINE)
	/*
	for i, expr in pipeline.exprs {
		if i > 0 && i == pipeline.exprs.len - 1 && pipeline.has_redirect() {
			e.write(if pipeline.is_append { ' >> ' } else { ' > ' })
			if expr is ast.CallExpr {
				e.write(r'"$(')
				defer {
					e.write(')"')
				}
			}
			e.expr(expr)
			return
		}

		if i > 0 {
			e.write(' | ')
		}
		e.expr(expr)
	}
	*/
}

fn (mut e Interpreter) selector_expr(expr ast.SelectorExpr) Value {
	// selector expr is used for only method call now.
	// method call is handled by call_expr. Nothing to do
	li_panic(@FN, @FILE, @LINE, 'unreachable')
}
