// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.messages { unreachable }
import cotowali.ast

fn (mut p Parser) parse_inline_shell() ?ast.InlineShell {
	$if trace_parser ? {
		p.trace_begin(@FN)
		defer {
			p.trace_end()
		}
	}

	key_tok := p.consume_with_assert(.key_sh, .key_pwsh, .key_inline)
	p.consume_with_check(.l_brace) ?
	mut parts := []ast.InlineShellPart{}

	for p.kind(0) !in [.eof, .r_brace] {
		tok := p.consume_with_assert(.inline_shell_content_text, .inline_shell_content_var)
		match tok.kind {
			.inline_shell_content_text {
				parts << tok
			}
			.inline_shell_content_var {
				parts << ast.Var{
					ident: ast.Ident{
						scope: p.scope
						pos: tok.pos
						text: tok.text.trim_prefix('%')
					}
				}
			}
			else {
				unreachable('invalid token `$tok.kind` in inline shell')
			}
		}
	}

	end_tok := p.consume_with_assert(.r_brace, .eof)
	return ast.InlineShell{
		key: key_tok
		pos: key_tok.pos.merge(end_tok.pos)
		parts: parts
	}
}
