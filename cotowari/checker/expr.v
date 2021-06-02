module checker

import cotowari.ast { Expr }
import cotowari.symbols { TypeSymbol }

fn (mut c Checker) expr(expr Expr) {
	match mut expr {
		ast.AsExpr, ast.ParenExpr { c.expr(expr.expr) }
		ast.CallFn { c.call_expr(mut expr) }
		ast.InfixExpr { c.infix_expr(expr) }
		ast.ArrayLiteral {}
		ast.IntLiteral {}
		ast.StringLiteral {}
		ast.Pipeline {}
		ast.PrefixExpr {}
		ast.Var {}
	}
}

fn (mut c Checker) infix_expr(expr ast.InfixExpr) {
	c.expr(expr.left)
	c.expr(expr.right)
	c.check_types(
		want: expr.left.type_symbol()
		want_label: 'left'
		got: expr.right.type_symbol()
		got_label: 'right'
		pos: expr.pos()
		synmetric: true
	) or { return }
}

fn (mut c Checker) call_expr(mut expr ast.CallFn) {
	name := expr.func.name()
	pos := Expr(expr).pos()

	mut scope := expr.scope
	func := scope.lookup_var(name) or {
		c.error('function `$name` is not defined', pos)
		return
	}
	expr.func.sym = func
	ts := func.type_symbol()
	if !func.is_function() {
		c.error('`$name` is not function (`$ts.name`)', pos)
		return
	}

	fn_info := ts.fn_info()
	params := fn_info.params
	expr.args

	args := expr.args
	if fn_info.is_varargs {
		min_len := params.len - 1
		if args.len < min_len {
			c.error('expected $min_len or more arguments, but got $args.len', pos)
			return
		}
	} else if args.len != params.len {
		c.error('expected $params.len arguments, but got $args.len', pos)
		return
	}

	mut call_args_types_ok := true
	varargs_elem_ts := if fn_info.is_varargs {
		scope.must_lookup_type(fn_info.varargs_elem)
	} else {
		// ?TypeSymbol(none)
		TypeSymbol{}
	}
	for i, arg in args {
		c.expr(arg)
		arg_ts := arg.type_symbol()
		param_ts := if fn_info.is_varargs && i >= params.len - 1 {
			varargs_elem_ts
		} else {
			scope.must_lookup_type(params[i])
		}

		c.check_types(want: param_ts, got: arg_ts, pos: arg.pos()) or { call_args_types_ok = false }
	}
	if !call_args_types_ok {
		return
	}
}
