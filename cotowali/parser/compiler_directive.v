// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.token { Token }
import cotowali.messages { unreachable }

fn (mut p Parser) process_compiler_directives() {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	for {
		p.skip_eol()
		if !(p.kind(0) == .hash && p.kind(1) == .ident) {
			return
		}
		p.process_compiler_directive()
	}
}

fn (mut p Parser) process_compiler_directive() {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	p.skip_eol()

	if !(p.kind(0) == .hash && p.kind(1) == .ident) {
		return
	}

	hash := p.consume_with_assert(.hash)
	start_pos := hash.pos

	ident := p.consume_with_assert(.ident)
	name := ident.text

	match name {
		'error', 'warning' {
			p.process_compiler_directive_error_or_warning(hash, ident)
		}
		else {
			p.skip_until_eol()
			p.error('unknown compiler directive `#$name`', start_pos.merge(p.pos(-1)))
		}
	}

	p.consume_with_check(.eol) or {
		// error was reported in consume_with_check
	}
}

fn (mut p Parser) process_compiler_directive_error_or_warning(hash Token, directive Token) {
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
	match directive.text {
		'error' { p.error(msg, pos) }
		'warning' { p.warn(msg, pos) }
		else { panic(unreachable('invalid directive ${directive.text}. expecting error or warning')) }
	}
}
