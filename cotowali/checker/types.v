module checker

import cotowali.ast { Expr }
import cotowali.symbols { TypeSymbol, builtin_type }
import cotowali.source { Pos }

struct TypeCheckingConfig {
	want       TypeSymbol [required]
	want_label string = 'expected'
	got        TypeSymbol [required]
	got_label  string = 'found'
	pos        Pos        [required]
	synmetric  bool
}

fn (mut c Checker) check_types(v TypeCheckingConfig) ? {
	if v.want.typ == v.got.typ {
		return
	}

	if !v.synmetric {
		if v.want.typ == builtin_type(.any) {
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
