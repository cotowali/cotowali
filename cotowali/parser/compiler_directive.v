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
	return p.kind(i) == .hash && p.kind(i + 1) in [.ident, .key_if]
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
		.if_, .endif {
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
			mut expected_cond := true
			for p.kind(0) == .not {
				p.consume()
				expected_cond = !expected_cond
			}

			cond := if p.kind(0).@is(.keyword) || p.kind(0) in [.ident, .bool_literal] {
				cond_tok := p.consume()
				if cond_tok.kind == .bool_literal {
					cond_tok.bool()
				} else {
					p.ctx.compiler_symbols.get_bool(cond_tok.text)
				}
			} else {
				p.skip_until_eol()
				if expected_cond {
					true // to parse branch, set the same value as expected_cond
				} else {
					false // same as above
				}
			}

			p.check(.eol) or {}

			if cond == expected_cond {
				p.inside_compiler_if_directive = true
			} else {
				p.skip_if_directive_branch()
			}
		}
		.endif {
			if !p.inside_compiler_if_directive {
				p.error(missing_if_directive(kind), start_pos.merge(p.pos(-1)))
				p.skip_until_eol()
			}
			p.inside_compiler_if_directive = false
		}
		else {
			panic(unreachable('invalid directive ${kind}. expecting #if or #endif'))
		}
	}
}

fn (mut p Parser) skip_if_directive_branch() {
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
			if kind := compiler_directive_kind_from_name(p.token(1).text) {
				match kind {
					.if_ { depth++ }
					.endif { depth-- }
					else {}
				}
			}
		}
		p.skip_until_eol()
	}
}
