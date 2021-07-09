module checker

import cotowali.ast { Expr }
import cotowali.symbols { TypeSymbol, builtin_type }
import cotowali.source { Pos }
import cotowali.errors { unreachable }

struct TypeCheckingConfig {
	want       TypeSymbol [required]
	want_label string = 'expected'
	got        TypeSymbol [required]
	got_label  string = 'found'
	pos        Pos        [required]
	synmetric  bool
}

fn is_same_type(a TypeSymbol, b TypeSymbol) bool {
	if a.typ == b.typ {
		return true
	}

	// treat `(int)` as equal to `int`
	if a_tuple_info := a.tuple_info() {
		if a_tuple_info.elements.len == 1 && a_tuple_info.elements[0] == b.typ {
			return true
		}
	}
	if b_tuple_info := b.tuple_info() {
		if b_tuple_info.elements.len == 1 && b_tuple_info.elements[0] == a.typ {
			return true
		}
	}

	return false
}

fn (mut c Checker) check_types(v TypeCheckingConfig) ? {
	if is_same_type(v.want, v.got) {
		return
	}

	if v.synmetric {
		if v.want.typ == builtin_type(.float) && v.got.typ == builtin_type(.int) {
			return
		}
		if v.want.typ == builtin_type(.int) && v.got.typ == builtin_type(.float) {
			return
		}
	} else {
		if v.want.typ == builtin_type(.any) {
			return
		}
		if v.want.typ == builtin_type(.float) && v.got.typ == builtin_type(.int) {
			return
		}
	}

	m1 := '`$v.want.name` ($v.want_label)'
	m2 := '`$v.got.name` ($v.got_label)'
	return c.error('mismatched types: $m1 and $m2', v.pos)
}

fn (mut c Checker) expect_bool_expr(expr Expr, context_name string) ? {
	if expr.typ() != builtin_type(.bool) {
		return c.error('non-bool type used as $context_name', expr.pos())
	}
}

fn (mut c Checker) expect_function_call(expr Expr) ?ast.CallExpr {
	if expr is ast.CallExpr {
		return expr
	}
	ts := expr.type_symbol()
	c.error('expected function call, but found $ts.name', expr.pos()) ?
	// wait for fix v bug
	// return c.error(...)
	panic(unreachable)
}
