module sh

import cotowali.ast
import cotowali.util { panic_and_value }

fn (mut e Emitter) reference(expr ast.Expr) {
	e.write(match expr {
		ast.PrefixExpr { e.ident_for(expr.expr) }
		else { panic_and_value('unimplemented', '') }
	})
}
