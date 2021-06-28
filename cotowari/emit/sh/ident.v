module sh

import cotowari.ast { ArrayLiteral, Expr, Var }
import cotowari.errors { unreachable }
import cotowari.util { panic_and_value }

fn (mut e Emitter) ident_for(expr Expr) string {
	return match expr {
		Var { expr.sym.full_name() }
		ArrayLiteral { e.new_tmp_var() }
		else { panic_and_value(unreachable(), '') }
	}
}
