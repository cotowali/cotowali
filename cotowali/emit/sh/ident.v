module sh

import cotowali.ast { ArrayLiteral, Expr, Var }
import cotowali.errors { unreachable }
import cotowali.util { panic_and_value }

fn (mut e Emitter) ident_for(expr Expr) string {
	return match expr {
		Var { expr.sym.full_name() }
		ArrayLiteral { e.new_tmp_var() }
		else { panic_and_value(unreachable('cannot take ident'), '') }
	}
}
