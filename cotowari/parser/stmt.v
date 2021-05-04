module parser

import cotowari.ast
import cotowari.errors { unreachable }

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
		.key_assert {
			tok := p.consume()
			return ast.AssertStmt{tok.pos, p.parse_expr({}) ?}
		}
		.key_fn {
			return ast.Stmt(p.parse_fn_decl() ?)
		}
		.key_let {
			return ast.Stmt(p.parse_let_stmt() ?)
		}
		.key_if {
			return ast.Stmt(p.parse_if_stmt() ?)
		}
		.key_for {
			return ast.Stmt(p.parse_for_in_stmt() ?)
		}
		.key_return {
			return ast.Stmt(p.parse_return_stmt() ?)
		}
		.inline_shell {
			tok := p.consume()
			return ast.InlineShell{
				pos: tok.pos
				text: tok.text
			}
		}
		else {
			if p.kind(0) == .ident && p.kind(1) == .op_assign {
				return ast.Stmt(p.parse_assign_stmt() ?)
			}
			return p.parse_expr_stmt()
		}
	}
}

fn (mut p Parser) parse_block(name string, locals []string) ?ast.Block {
	p.open_scope(name)
	for local in locals {
		p.scope.register_var(name: local) or { panic(err) }
	}
	defer {
		p.close_scope()
	}
	block := p.parse_block_without_new_scope() ?
	return block
}

fn (mut p Parser) parse_block_without_new_scope() ?ast.Block {
	p.consume_with_check(.l_brace) ?
	p.skip_eol() // ignore eol after brace.
	mut node := ast.Block{
		scope: p.scope
	}
	for {
		if _ := p.consume_if_kind_eq(.r_brace) {
			return node
		}
		node.stmts << p.parse_stmt()
	}
	panic(unreachable)
}

fn (mut p Parser) parse_let_stmt() ?ast.AssignStmt {
	p.consume_with_assert(.key_let)
	ident := p.consume_with_check(.ident) ?
	name := ident.text
	p.consume_with_check(.op_assign) ?

	v := ast.Var{
		scope: p.scope
		pos: ident.pos
		sym: p.scope.register_var(name: name, pos: ident.pos) or { return p.duplicated_error(name) }
	}
	return ast.AssignStmt{
		left: v
		right: p.parse_expr({}) ?
	}
}

fn (mut p Parser) parse_assign_stmt() ?ast.AssignStmt {
	ident := p.consume_with_check(.ident) ?
	name := ident.text
	p.consume_with_check(.op_assign) ?
	return ast.AssignStmt{
		left: ast.Var{
			scope: p.scope
			pos: ident.pos
			sym: p.scope.lookup_or_register_var(name: name, pos: ident.pos)
		}
		right: p.parse_expr({}) ?
	}
}

fn (mut p Parser) parse_if_branch(name string) ?ast.IfBranch {
	cond := p.parse_expr({}) ?
	block := p.parse_block(name, []) ?
	return ast.IfBranch{
		cond: cond
		body: block
	}
}

fn (mut p Parser) parse_if_stmt() ?ast.IfStmt {
	p.consume_with_assert(.key_if)

	cond := p.parse_expr({}) ?
	mut branches := [ast.IfBranch{
		cond: cond
		body: p.parse_block('if_$p.count', []) ?
	}]
	mut has_else := false
	mut elif_count := 0
	for {
		p.consume_if_kind_eq(.key_else) or { break }

		if _ := p.consume_if_kind_eq(.key_if) {
			elif_cond := p.parse_expr({}) ?
			branches << ast.IfBranch{
				cond: elif_cond
				body: p.parse_block('elif_${p.count}_$elif_count', []) ?
			}
			elif_count++
		} else {
			has_else = true
			branches << ast.IfBranch{
				body: p.parse_block('else_$p.count', []) ?
			}
			break
		}
	}
	p.count++
	return ast.IfStmt{
		branches: branches
		has_else: has_else
	}
}

fn (mut p Parser) parse_for_in_stmt() ?ast.ForInStmt {
	p.consume_with_assert(.key_for)
	ident := p.consume_with_check(.ident) ?
	p.consume_with_check(.key_in) ?
	expr := p.parse_expr({}) ?
	body := p.parse_block('for_$p.count', [ident.text]) ?
	p.count++
	return ast.ForInStmt{
		val: ast.Var{
			scope: body.scope
			pos: ident.pos
			sym: body.scope.lookup_var(ident.text) or { panic(unreachable) }
		}
		expr: expr
		body: body
	}
}

fn (mut p Parser) parse_return_stmt() ?ast.ReturnStmt {
	tok := p.consume_with_assert(.key_return)
	return ast.ReturnStmt{
		token: tok
		expr: p.parse_expr({}) ?
	}
}
