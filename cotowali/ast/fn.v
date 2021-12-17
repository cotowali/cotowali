// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ast

import cotowali.source { Pos }
import cotowali.token { Token }
import cotowali.symbols {
	BuiltinFunctionKey,
	FunctionParam,
	FunctionTypeInfo,
	Scope,
	Type,
	TypeSymbol,
	builtin_function_id,
	builtin_type,
}
import cotowali.messages { undefined }
import cotowali.util { li_panic }

pub struct FnDecl {
pub:
	parent_scope &Scope
	has_body     bool
	is_method    bool
pub mut:
	attrs         []Attr
	pipe_in_param Var
	sym           &symbols.Var
	params        []FnParam
	body          Block
}

pub struct FnParam {
pub:
	pos     Pos
	default Expr = Empty{}
pub mut:
	var_ Var
}

pub fn (param &FnParam) name() string {
	return param.var_.name()
}

pub fn (param &FnParam) default() ?Expr {
	return if param.default !is Empty { param.default } else { none }
}

pub fn (param &FnParam) type_symbol() &TypeSymbol {
	return Expr(param.var_).type_symbol()
}

pub fn (f FnDecl) function_info() FunctionTypeInfo {
	return f.type_symbol().function_info() or { li_panic(@FILE, @LINE, err) }
}

pub fn (f FnDecl) type_symbol() &TypeSymbol {
	return f.sym.type_symbol()
}

pub fn (f FnDecl) signature() string {
	return f.type_symbol().signature() or { li_panic(@FILE, @LINE, err) }
}

pub fn (f FnDecl) ret_type_symbol() &TypeSymbol {
	return f.parent_scope.must_lookup_type(f.function_info().ret)
}

pub fn (f FnDecl) pipe_in_param() ?Var {
	if f.pipe_in_param.name() == '' {
		return none
	}
	return f.pipe_in_param
}

pub fn (f FnDecl) is_test() bool {
	return f.attrs.any(it.kind() == .test)
}

pub fn (f FnDecl) get_run_test_call_expr() CallExpr {
	scope := f.sym.scope() or { li_panic(@FILE, @LINE, 'scope is nil') }
	testing := scope.root().must_get_child('testing')
	sq_token := Token{
		kind: .single_quote
		text: "'"
	}
	return CallExpr{
		scope: testing
		func: Var{
			sym: testing.must_lookup_var('run_test')
			ident: Ident{
				text: 'run_test'
				scope: testing
			}
		}
		args: [
			// label
			Expr(StringLiteral{
				scope: scope
				open: sq_token
				close: sq_token
				contents: [
					StringLiteralContent(Token{
						kind: .string_literal_content_text
						text: f.sym.display_name()
					}),
				]
			}),
			// test function name
			Expr(StringLiteral{
				scope: scope
				open: sq_token
				close: sq_token
				contents: [
					StringLiteralContent(Token{
						kind: .string_literal_content_text
						text: f.sym.name_for_ident()
					}),
				]
			}),
		]
	}
}

pub fn (f FnDecl) children() []Node {
	mut children := []Node{cap: f.params.len + 1}
	children << f.params.map(Node(it))
	children << Stmt(f.body)
	return children
}

pub fn (p FnParam) children() []Node {
	return [Node(Expr(p.var_)), p.default]
}

fn (mut r Resolver) fn_decl(mut decl FnDecl) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	if decl.attrs.any(it.kind() == .mangle) {
		decl.sym.mangle = true
	}
	for mut param in decl.params {
		r.fn_param(mut param)
	}
	r.block(decl.body)
}

fn (mut r Resolver) fn_param(mut param FnParam) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
	r.var_(mut param.var_, is_left_of_assignment: true)
	if default_expr := param.default() {
		r.expr(default_expr)
	}
}

// --

pub struct ReturnStmt {
pub:
	expr Expr
}

[inline]
pub fn (s &ReturnStmt) children() []Node {
	return [Node(s.expr)]
}

fn (mut r Resolver) return_stmt(stmt ReturnStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
	r.expr(stmt.expr)
}

pub struct YieldStmt {
pub:
	pos  Pos
	expr Expr
}

fn (mut r Resolver) yield_stmt(stmt YieldStmt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.expr(stmt.expr)
}

[inline]
pub fn (s &YieldStmt) children() []Node {
	return [Node(s.expr)]
}

// --

pub struct CallCommandExpr {
pub:
	pos     Pos
	command string
	args    []Expr
pub mut:
	scope &Scope
}

[inline]
pub fn (expr &CallCommandExpr) children() []Node {
	return expr.args.map(Node(it))
}

fn (mut r Resolver) call_command_expr(expr CallCommandExpr, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}
	r.exprs(expr.args, opt)
}

pub struct CallExpr {
mut:
	typ Type
pub:
	pos Pos
pub mut:
	scope   &Scope
	func_id u64
	func    Expr
	args    []Expr
}

pub fn (e CallExpr) is_method() bool {
	return if _ := e.receiver() { true } else { false }
}

pub fn (e CallExpr) receiver() ?Expr {
	if e.func is SelectorExpr {
		return e.func.left
	}
	return none
}

pub fn (e CallExpr) function_info() FunctionTypeInfo {
	return e.func.type_symbol().function_info() or { li_panic(@FILE, @LINE, err) }
}

pub fn (e CallExpr) is_builtin_function_call(key BuiltinFunctionKey) bool {
	return e.func_id == builtin_function_id(key)
}

pub fn (expr &CallExpr) children() []Node {
	mut children := []Node{cap: expr.args.len + 1}
	children << expr.func
	children << expr.args.map(Node(it))
	return children
}

fn (mut r Resolver) call_expr(mut expr CallExpr, opt ResolveExprOpt) {
	$if trace_resolver ? {
		r.trace_begin(@FN)
		defer {
			r.trace_end()
		}
	}

	r.call_expr_func(mut expr, mut &expr.func)
	r.exprs(expr.args, opt)
}

fn (mut r Resolver) call_expr_func(mut e CallExpr, mut func Expr) {
	match mut func {
		Var {
			r.call_expr_func_var(mut e, mut func)
		}
		ModuleItem {
			r.module_item(mut func)
			if func.is_resolved {
				r.call_expr_func(mut e, mut &func.item)
			}
		}
		SelectorExpr {
			r.selector_expr(func)
			r.call_expr_func_var(mut e, mut &func.ident)
		}
		else {
			r.error('cannot call `$e.func.type_symbol().name`', e.pos)
		}
	}
}

fn (e CallExpr) lookup_sym(name string, scope &Scope) ?&symbols.Var {
	if receiver := e.receiver() {
		receiver_ts := receiver.type_symbol()
		return receiver_ts.lookup_method(name) or {
			return error(undefined(.function, '${receiver_ts.name}.$name'))
		}
	} else {
		return scope.lookup_var(name) or { return error(undefined(.function, name)) }
	}
}

// TODO: Refactor
fn (mut r Resolver) call_expr_func_var(mut e CallExpr, mut func Var) {
	name := func.name()
	sym := e.lookup_sym(name, func.scope()) or {
		r.error(err.msg, e.pos)
		return
	}

	func.sym = sym

	ts := sym.type_symbol()
	if !sym.is_function() {
		r.error('`$sym.name` is not function (`$ts.name`)', e.pos)
		return
	}

	function_info := ts.function_info() or { li_panic(@FILE, @LINE, err) }
	e.typ = function_info.ret
	e.func_id = sym.id
	if owner := e.scope.owner() {
		if sym.id == builtin_function_id(.read) {
			owner_function_info := owner.type_symbol().function_info() or {
				li_panic(@FILE, @LINE, err)
			}
			mut pipe_in := e.scope.must_lookup_type(owner_function_info.pipe_in)
			if pipe_in_sequence_info := pipe_in.sequence_info() {
				pipe_in = e.scope.must_lookup_type(pipe_in_sequence_info.elem)
			}
			new_fn_params := (if pipe_in_tuple_info := pipe_in.tuple_info() {
				elements := pipe_in_tuple_info.elements
				elements.map(e.scope.lookup_or_register_reference_type(target: it.typ).typ)
			} else {
				[e.scope.lookup_or_register_reference_type(target: pipe_in.typ).typ]
			}).map(FunctionParam{
				typ: it
			})
			func.sym = if new_fn := e.scope.register_function(name: sym.name, params: new_fn_params) {
				new_fn
			} else {
				// already registered
				e.scope.must_lookup_var(sym.name)
			}
		}
	}
}

pub struct Nameof {
	scope &Scope
pub:
	args []Expr
	pos  Pos
}

pub fn (expr &Nameof) typ() Type {
	return builtin_type(.string)
}

pub fn (expr &Nameof) pos() Pos {
	return expr.pos
}

pub fn (expr &Nameof) scope() &Scope {
	return expr.scope
}

pub fn (expr &Nameof) children() []Node {
	return expr.args.map(Node(it))
}

pub fn (expr &Nameof) value() string {
	msg := 'cannot take name'
	if expr.args.len != 1 {
		li_panic(@FILE, @LINE, msg)
	}

	arg := expr.args[0]
	match arg {
		Var {
			return (arg.sym() or { li_panic(@FILE, @LINE, msg) }).name
		}
		ModuleItem {
			return (arg.item.sym() or { li_panic(@FILE, @LINE, msg) }).display_name()
		}
		else {}
	}
	li_panic(@FILE, @LINE, msg)
}

fn (mut r Resolver) nameof(expr Nameof, opt ResolveExprOpt) {
	if expr.args.len != 1 {
		return
	}
	r.expr(expr.args[0], opt)
}

pub struct Typeof {
	scope &Scope
pub:
	args []Expr
	pos  Pos
}

pub fn (expr &Typeof) typ() Type {
	return builtin_type(.string)
}

pub fn (expr &Typeof) pos() Pos {
	return expr.pos
}

pub fn (expr &Typeof) scope() &Scope {
	return expr.scope
}

pub fn (expr &Typeof) children() []Node {
	return expr.args.map(Node(it))
}

pub fn (expr &Typeof) value() string {
	if expr.args.len != 1 {
		li_panic(@FILE, @LINE, 'Typeof.value: expr.args.len = $expr.args.len')
	}
	return expr.args[0].type_symbol().name
}

fn (mut r Resolver) typeof_(expr Typeof, opt ResolveExprOpt) {
	if expr.args.len != 1 {
		return
	}
	r.expr(expr.args[0], opt)
}
