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
		.key_if {
			return ast.Stmt(p.parse_if_stmt() ?)
		}
		else {
			if p.kind(0) == .ident && p.kind(1) == .op_assign {
				return ast.Stmt(p.parse_assign_stmt() ?)
			}
			return p.parse_expr_stmt()
		}
	}
}

fn (mut p Parser) parse_block(name string) ?ast.Block {
	p.open_scope(name)
	defer { p.close_scope() }
	block := p.parse_block_without_new_scope() ?
	return block
}

fn (mut p Parser) parse_block_without_new_scope() ?ast.Block {
	p.consume_with_check(.l_brace) ?
	p.skip_eol() // ignore eol after brace.
	mut node := ast.Block{ scope: p.scope }
	for {
		if _ := p.consume_if_kind_is(.r_brace) {
			return node
		}
		node.stmts << p.parse_stmt()
	}
	p.consume_with_check(.r_brace) ?
	panic('unreachable code')
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
	node.body = p.parse_block_without_new_scope() ?
	return node
}

fn (mut p Parser) parse_let_stmt() ?ast.AssignStmt {
	p.consume_with_assert(.key_let)
	name := (p.consume_with_check(.ident) ?).text
	p.consume_with_check(.op_assign) ?

	v := p.scope.register_var(symbols.new_var(name)) or {
		println(p.scope)
		return IError(p.error('$name is duplicated'))
	}
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

fn (mut p Parser) parse_if_branch(name string) ?ast.IfBranch {
	cond := p.parse_expr({}) ?
	block := p.parse_block(name) ?
	return ast.IfBranch {
		cond: cond
		body: block
	}
}

fn (mut p Parser) parse_if_stmt() ?ast.IfStmt {
	p.consume_with_assert(.key_if)

	cond := p.parse_expr({}) ?
	mut branches := [ast.IfBranch{
		cond: cond
		body: p.parse_block('if') ?
	}]
	mut has_else := false
	for {
		p.consume_if_kind_is(.key_else) or { break }

		if _ := p.consume_if_kind_is(.key_if) {
			elif_cond := p.parse_expr({}) ?
			branches << ast.IfBranch {
				cond: elif_cond
				body: p.parse_block('elif') ?
			}
		} else{
			has_else = true
			branches << ast.IfBranch {
				body: p.parse_block('else') ?
			}
			break
		}
	}
	return ast.IfStmt{
		branches: branches
		has_else: has_else
	}
}
