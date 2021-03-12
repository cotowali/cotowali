module parser

import vash.source { Source }
import vash.lexer { Lexer }
import vash.token { Token }
import vash.ast

pub struct Parser {
mut:
	lexer     Lexer
	buf       []token.Token
	token_idx int
	file			ast.File
}

pub fn (p &Parser) token(i int) Token {
	if i >= p.buf.len {
		panic('cannot take token($i) (p.buf.len = $p.buf.len)')
	}
	if i < 0 {
		panic('cannot take negative token($i)')
	}
	return p.buf[(p.token_idx + i) % p.buf.len]
}

pub fn (mut p Parser) consume() {
	p.buf[p.token_idx % p.buf.len] = p.lexer.read()
	p.token_idx++
}

[inline]
pub fn new(lexer Lexer) Parser {
	mut p := Parser{
		lexer: lexer
		buf: []Token{len: 3} // LL(3)
	}
	for _ in 0 .. p.buf.len {
		p.consume()
	}
	p.token_idx = 0
	return p
}

pub fn (p &Parser) source() Source {
	return p.lexer.source
}

pub fn (mut p Parser) parse() ast.File {
	p.file = ast.File{
		path: p.source().path
	}
	p.file.stmts = p.stmts()
	return p.file
}

pub fn parse_file(path string) ?ast.File {
	s := source.read_file(path) ?
	mut p := new(lexer.new(s))
	return p.parse()
}

fn (mut p Parser) stmts() []ast.Stmt {
	return [p.parse_stmt()]
}

fn (mut p Parser) parse_stmt() ast.Stmt {
	return p.parse_pipeline()
}

fn (mut p Parser) parse_pipeline() ast.Pipeline {
	return ast.Pipeline{
		commands: p.parse_commands()
	}
}

fn (mut p Parser) parse_commands() []ast.Command {
	return [p.parse_command()]
}

fn (mut p Parser) parse_command() ast.Command {
	return ast.Command{
		expr: p.parse_expr()
	}
}

fn (mut p Parser) parse_expr() ast.Expr {
	return p.parse_call_expr()
}

fn (mut p Parser) parse_call_expr() ast.CallExpr {
	return ast.CallExpr{
		name: 'echo'
		args: [p.parse_value()]
	}
}

fn (mut p Parser) parse_value() ast.Expr {
	tok := p.token(0)
	return match tok.kind {
		.int_lit {
			p.consume()
			ast.Expr(ast.IntLiteral{
				token: tok
			})
		}
		else {
			ast.Expr(p.error('unexpected token $tok'))
		}
	}
}

fn (mut p Parser) error(msg string) ast.ErrorNode {
	node := ast.ErrorNode{
		message: msg
	}
	p.consume()
	p.file.errors << node
	return node
}
