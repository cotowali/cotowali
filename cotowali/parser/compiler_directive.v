// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.token { Token }
import cotowali.messages { unreachable }
import cotowali.compiler_directives {
	CompilerDirectiveKind,
	compiler_directive_kind_from_name,
	missing_endif_directive,
	missing_if_directive,
}

fn (mut p Parser) process_compiler_directives() {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	for {
		p.skip_eol()
		if !(p.is_compiler_directive(0)) {
			return
		}
		p.process_compiler_directive()
	}
}

fn (mut p Parser) is_compiler_directive(i int) bool {
	return p.kind(i) == .hash && p.kind(i + 1) in [.ident, .key_if, .key_else]
}

fn (mut p Parser) process_compiler_directive() {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.skip_eol()

	if !p.is_compiler_directive(0) {
		return
	}

	hash := p.consume_with_assert(.hash)
	start_pos := hash.pos

	ident := p.consume()

	defer {
		p.consume_with_check(.eol) or {
			// error was reported in consume_with_check
		}
	}

	kind := compiler_directive_kind_from_name(ident.text) or {
		p.skip_until_eol()
		p.error(err.msg, start_pos.merge(p.pos(-1)))
		return
	}
	match kind {
		.error, .warning {
			p.process_compiler_directive_error_or_warning(hash, kind)
		}
		.define, .undef {
			p.process_compiler_directive_define_undef(hash, kind)
		}
		.if_, .else_, .endif {
			p.process_compiler_directive_if_else(hash, kind)
		}
	}
}

fn (mut p Parser) process_compiler_directive_error_or_warning(hash Token, kind CompilerDirectiveKind) {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	mut msg_start_pos := p.pos(0)
	p.skip_until_eol()
	last_pos := p.pos(-1)
	msg_pos := msg_start_pos.merge(last_pos)
	pos := hash.pos.merge(last_pos)

	msg := p.source().slice(msg_pos.begin(), msg_pos.end())
	match kind {
		.error { p.error(msg, pos) }
		.warning { p.warn(msg, pos) }
		else { panic(unreachable('invalid directive ${kind}. expecting error or warning')) }
	}
}

fn (mut p Parser) read_define_directive_value() string {
	mut value_pos := p.pos(0)
	p.skip_until_eol()
	value_pos = value_pos.merge(p.pos(-1))
	mut value := p.source().slice(value_pos.begin(), value_pos.end())
	first, last := value[0], value[value.len - 1]
	if (first == `"` && last == `"`) || (first == `'` && last == `'`) {
		value = value[1..value.len - 1]
	}
	return value
}

fn (mut p Parser) process_compiler_directive_define_undef(hash Token, kind CompilerDirectiveKind) {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	if p.kind(0) in [.eol, .eof] {
		p.unexpected_token_error(p.token(0))
		return
	}

	key := p.consume()

	match kind {
		.define {
			if p.kind(0) in [.eol, .eof] {
				p.ctx.compiler_symbols.define(key.text)
			} else {
				value := p.read_define_directive_value()
				p.ctx.compiler_symbols.define_with_value(key.text, value)
			}
		}
		.undef {
			p.ctx.compiler_symbols.undef(key.text)
		}
		else {
			panic(unreachable('invalid directive ${kind}. expecting #define or #undef'))
		}
	}
}

fn (mut p Parser) if_directive_cond_is_true() bool {
	return p.if_directive_cond_calc_expr()
}

fn (mut p Parser) if_directive_cond_calc_expr() bool {
	return p.if_directive_cond_calc_or_expr()
}

fn (mut p Parser) if_directive_cond_calc_or_expr() bool {
	mut value := p.if_directive_cond_calc_and_expr()
	for {
		if p.kind(0) == .eol && p.kind(1) == .logical_or {
			//       v p.kind(0) == .eol
			// #if a
			//     || b
			// //  ^^ p.kind(1) == .logical_or
			p.consume()
		}

		if p.kind(0) != .logical_or {
			break
		}

		p.consume()
		p.skip_eol()
		right := p.if_directive_cond_calc_and_expr()
		value = value || right
	}
	return value
}

fn (mut p Parser) if_directive_cond_calc_and_expr() bool {
	mut value := p.if_directive_cond_value()
	for {
		if p.kind(0) == .eol && p.kind(1) == .logical_and {
			// same as `||` expr
			p.consume()
		}

		if p.kind(0) != .logical_and {
			break
		}

		p.consume()
		p.skip_eol()
		right := p.if_directive_cond_value()
		value = value && right
	}
	return value
}

fn (mut p Parser) if_directive_cond_value() bool {
	if _ := p.consume_if_kind_eq(.not) {
		return !p.if_directive_cond_value()
	}

	if _ := p.consume_if_kind_eq(.l_paren) {
		p.skip_eol()
		defer {
			p.skip_eol()
			p.consume_with_check(.r_paren) or {}
		}
		return p.if_directive_cond_calc_expr()
	}

	if p.kind(0).@is(.keyword) || p.kind(0) in [.ident, .bool_literal, .int_literal] {
		cond_tok := p.consume()
		return match cond_tok.kind {
			.bool_literal { cond_tok.bool() }
			.int_literal { cond_tok.text.int() != 0 }
			else { p.ctx.compiler_symbols.get_bool(cond_tok.text) }
		}
	}

	p.unexpected_token_error(p.token(0))
	return true // when error, use true to try to parse branch to show better error
}

fn (mut p Parser) process_compiler_directive_if_else(hash Token, kind CompilerDirectiveKind) {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	start_pos := hash.pos

	match kind {
		.if_ {
			cond_is_true := p.if_directive_cond_is_true()
			p.check(.eol) or {}

			if cond_is_true {
				p.if_directive_depth++
			} else {
				p.skip_if_else_directive_branch(.if_)
				if !p.is_compiler_directive(0) {
					// without #else
					return
				}

				next_kind := compiler_directive_kind_from_name(p.token(1).text) or {
					p.skip_until_eol()
					p.error(err.msg, start_pos.merge(p.pos(-1)))
					return
				}
				if next_kind != .else_ {
					panic(unreachable('expecting #else'))
				}

				p.if_directive_depth++
				p.consume_with_assert(.hash)
				p.consume_with_assert(.key_else)
				p.check(.eol) or {}
			}
		}
		.else_ {
			if p.if_directive_depth == 0 {
				p.error(missing_if_directive(kind), start_pos.merge(p.pos(-1)))
				p.skip_until_eol()
			}
			// active else branch is handled in `.if_`
			// just skip branch here
			p.if_directive_depth--
			p.skip_if_else_directive_branch(.else_)
		}
		.endif {
			if p.if_directive_depth == 0 {
				p.error(missing_if_directive(kind), start_pos.merge(p.pos(-1)))
				p.skip_until_eol()
			}
			p.if_directive_depth--
		}
		else {
			panic(unreachable('invalid directive ${kind}. expecting #if or #endif'))
		}
	}
}

fn (mut p Parser) skip_if_else_directive_branch(kind CompilerDirectiveKind) {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	mut depth := 1
	for depth > 0 {
		p.skip_eol()
		if p.kind(0) == .eof {
			p.error(missing_endif_directive(), p.pos(0))
			break
		}
		if p.is_compiler_directive(0) {
			if next_kind := compiler_directive_kind_from_name(p.token(1).text) {
				match next_kind {
					.if_ {
						depth++
					}
					.else_ {
						if depth == 1 && kind != .else_ {
							break
						}
					}
					.endif {
						depth--
					}
					else {}
				}
			}
		}
		p.skip_until_eol()
	}
}
