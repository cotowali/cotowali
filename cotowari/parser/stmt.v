module parser

import cotowari.ast
import cotowari.symbols

fn (mut p Parser) parse_stmt() ast.Stmt {
	stmt := p.try_parse_stmt() or {
		p.skip_until_eol()
		ast.EmptyStmt{}
	}
	p.skip_eol()
	return stmt
}

fn (mut p Parser) try_parse_stmt() ?ast.Stmt {
	match p.kind(0) {
		.key_fn {
			return ast.Stmt(p.parse_fn_decl() ?)
		}
		.key_let {
			return ast.Stmt(p.parse_let_stmt() ?)
		}
		else {
			if p.kind(0) == .ident && p.kind(1) == .op_assign {
				return ast.Stmt(p.parse_assign_stmt() ?)
			}
			return p.parse_expr_stmt()
		}
	}
}

fn (mut p Parser) parse_fn_decl() ?ast.FnDecl {
	p.consume_with_assert(.key_fn)
	name := p.consume().text

	p.scope.register(symbols.new_fn(name)) ?

	p.open_scope(name)
	defer {
		p.close_scope()
	}

	mut node := ast.FnDecl{
		name: name
		body: ast.Block{
			scope: p.scope
		}
		params: []
	}

	p.consume_with_check(.l_paren) ?
	if p.@is(.ident) {
		for {
			ident := p.consume_with_check(.ident) ?
			node.params << (p.scope.register_var(symbols.new_var(ident.text)) ?)
			if p.@is(.r_paren) {
				break
			} else {
				p.consume_with_check(.comma) ?
			}
		}
	}
	p.consume_with_check(.r_paren) ?

	p.consume_with_check(.l_brace) ?
	p.skip_eol()

	for {
		node.body.stmts << p.parse_stmt()
		if _ := p.consume_if_kind_is(.r_brace) {
			return node
		}
	}
	panic('unreachable code')
}

fn (mut p Parser) parse_let_stmt() ?ast.AssignStmt {
	p.consume_with_assert(.key_let)
	name := (p.consume_with_check(.ident) ?).text
	p.consume_with_check(.op_assign) ?

	v := p.scope.register_var(symbols.new_var(name)) ?
	return ast.AssignStmt{
		left: v
		right: p.parse_expr({}) ?
	}
}

fn (mut p Parser) parse_assign_stmt() ?ast.AssignStmt {
	name := (p.consume_with_check(.ident) ?).text
	p.consume_with_check(.op_assign) ?
	return ast.AssignStmt{
		left: symbols.new_scope_var(name, p.scope)
		right: p.parse_expr({}) ?
	}
}
