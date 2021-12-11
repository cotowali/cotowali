// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module pwsh

import cotowali.ast { Expr }
import cotowali.symbols { builtin_type }
import cotowali.util { li_panic }

[params]
struct ExprOpt {
	paren bool
}

fn (mut e Emitter) expr(expr Expr, opt ExprOpt) {
	if opt.paren {
		e.write('(')
		defer {
			e.write(')')
		}
	}
	match expr {
		ast.AsExpr { e.as_expr(expr, opt) }
		ast.BoolLiteral { e.bool_literal(expr, opt) }
		ast.CallCommandExpr { e.call_command_expr(expr, opt) }
		ast.CallExpr { e.call_expr(expr, opt) }
		ast.DefaultValue { e.default_value(expr, opt) }
		ast.DecomposeExpr { e.decompose_expr(expr, opt) }
		ast.Empty {}
		ast.FloatLiteral { e.float_literal(expr, opt) }
		ast.IntLiteral { e.int_literal(expr, opt) }
		ast.ParenExpr { e.paren_expr(expr, opt) }
		ast.Pipeline { e.pipeline(expr, opt) }
		ast.InfixExpr { e.infix_expr(expr, opt) }
		ast.IndexExpr { e.index_expr(expr, opt) }
		ast.MapLiteral { e.map_literal(expr, opt) }
		ast.ModuleItem { e.module_item(expr, opt) }
		ast.NullLiteral { e.null_literal(expr, opt) }
		ast.PrefixExpr { e.prefix_expr(expr, opt) }
		ast.SelectorExpr { e.selector_expr(expr, opt) }
		ast.Nameof { panic('unimplemented') }
		ast.Typeof { e.write("'$expr.value()'") }
		ast.ArrayLiteral { e.array_literal(expr, opt) }
		ast.StringLiteral { e.string_literal(expr, opt) }
		ast.Var { e.var_(expr, opt) }
	}
}

fn (mut e Emitter) as_expr(expr ast.AsExpr, opt ExprOpt) {
	if call_expr := expr.overloaded_function_call_expr() {
		e.call_expr(call_expr, opt)
		return
	}
	e.write('[')
	e.write(Expr(expr).type_symbol().resolved().name)
	e.write(']')
	e.expr(expr.expr, paren: true)
}

fn (mut e Emitter) decompose_expr(expr ast.DecomposeExpr, opt ExprOpt) {
	// any decompose expr handled in other places (e.g. paren_expr)
	li_panic(@FILE, @LINE, 'invalid decompose')
}

fn (mut e Emitter) default_value(expr ast.DefaultValue, opt ExprOpt) {
	ts := Expr(expr).type_symbol()
	ts_resolved := ts.resolved()

	if tuple_info := ts_resolved.tuple_info() {
		e.paren_expr(ast.ParenExpr{
			scope: expr.scope
			exprs: tuple_info.elements.map(Expr(ast.DefaultValue{
				typ: it.typ
				scope: expr.scope
			}))
		}, opt)
		return
	}

	if ts_resolved.kind() == .array {
		e.write('@()')
		return
	}

	e.write(match ts_resolved.typ {
		builtin_type(.bool) { r'$false' }
		builtin_type(.int), builtin_type(.float) { '0' }
		else { '""' }
	})
}

fn (mut e Emitter) index_expr(expr ast.IndexExpr, opt ExprOpt) {
	e.expr(expr.left)
	e.write('[')
	e.expr(expr.index, paren: true)
	e.write(']')
}

fn (mut e Emitter) infix_expr(expr ast.InfixExpr, opt ExprOpt) {
	op := expr.op
	if !op.kind.@is(.infix_op) {
		li_panic(@FILE, @LINE, 'not a infix op')
	}

	if call_expr := expr.overloaded_function_call_expr() {
		e.call_expr(call_expr, opt)
		return
	}

	ts := Expr(expr).type_symbol()
	ts_resolved := ts.resolved()
	is_int := ts_resolved.typ == builtin_type(.int)

	match expr.left.type_symbol().resolved().kind() {
		.tuple {
			e.infix_expr_for_tuple(expr, opt)
			return
		}
		.array {
			e.infix_expr_for_array(expr, opt)
			return
		}
		else {}
	}

	if op.kind == .pow {
		if is_int {
			e.write('[int]')
		}
		e.write('[Math]::Pow(')
		{
			e.expr(expr.left)
			e.write(', ')
			e.expr(expr.right)
		}
		e.write(')')
		return
	}

	op_text := match op.kind {
		.eq { '-eq' }
		.ne { '-ne' }
		.lt { '-lt' }
		.le { '-le' }
		.gt { '-gt' }
		.ge { '-ge' }
		.logical_and { '-and' }
		.logical_or { '-or' }
		.plus { '+' }
		.minus { '-' }
		.mul { '*' }
		.div { '/' }
		.mod { '%' }
		else { panic('unimplemented') }
	}

	if op.kind == .div && is_int {
		e.write('[int][Math]::Floor(')
		defer {
			e.write(')')
		}
	}

	e.expr(expr.left, paren: true)
	e.write(' $op_text ')
	e.expr(expr.right, paren: true)
}

fn (mut e Emitter) infix_expr_for_pwsh_array(expr ast.InfixExpr, opt ExprOpt) {
	match expr.op.kind {
		.eq { e.pwsh_array_eq(expr.left, expr.right) }
		.ne { e.pwsh_array_ne(expr.left, expr.right) }
		.plus { e.pwsh_array_concat(expr.left, expr.right) }
		else { li_panic(@FILE, @LINE, 'wrong op $expr.op.text for array') }
	}
}

fn (mut e Emitter) infix_expr_for_tuple(expr ast.InfixExpr, opt ExprOpt) {
	e.infix_expr_for_pwsh_array(expr, opt)
}

fn (mut e Emitter) infix_expr_for_array(expr ast.InfixExpr, opt ExprOpt) {
	e.infix_expr_for_pwsh_array(expr, opt)
}

fn (mut e Emitter) module_item(expr ast.ModuleItem, opt ExprOpt) {
	if !expr.is_resolved() {
		li_panic(@FILE, @LINE, 'unresolved module item')
	}
	e.expr(expr.item, opt)
}

fn (mut e Emitter) paren_expr(expr ast.ParenExpr, opt ExprOpt) {
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
}

fn (mut e Emitter) prefix_expr(expr ast.PrefixExpr, opt ExprOpt) {
	op := expr.op
	if !op.kind.@is(.prefix_op) {
		li_panic(@FILE, @LINE, 'not a prefix op')
	}

	if call_expr := expr.overloaded_function_call_expr() {
		e.call_expr(call_expr, opt)
		return
	}

	if op.kind == .amp {
		e.write('([ref]')
		e.expr(expr.expr)
		e.write(')')
		return
	}

	e.write(match op.kind {
		.not { '! ' }
		.plus { '+' }
		.minus { '-' }
		else { li_panic(@FILE, @LINE, 'invalid op $op.text') }
	})
	e.expr(expr.expr, paren: true)
}

fn (mut e Emitter) pipeline(pipeline ast.Pipeline, opt ExprOpt) {
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
}

fn (mut e Emitter) selector_expr(expr ast.SelectorExpr, opt ExprOpt) {
	// selector expr is used for only method call now.
	// method call is handled by call_expr. Nothing to do
}

fn (mut e Emitter) var_(v ast.Var, opt ExprOpt) {
	e.write(e.pwsh_var(v))
}
