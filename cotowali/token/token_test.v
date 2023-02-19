// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module token

import cotowali.source { none_pos, pos }

fn test_eq() {
	t := Token{.unknown, 'text', pos(i: 10)}

	assert t == Token{
		...t
		pos: none_pos()
	}
	assert t != Token{
		...t
		kind: .eof
	}
	assert t != Token{
		...t
		text: 'x'
	}
}

fn test_token_str() {
	t1 := Token{.ident, 'a', none_pos()}
	assert t1.str() == "Token{ .ident, 'a', none }"
	assert t1.short_str() == "{ .ident, 'a' }"

	p := pos(i: 0)
	text, text_want := '\n\r\\', r'\n\r\\'
	t2 := Token{.ident, text, p}
	assert t2.str() == "Token{ .ident, '${text_want}', ${p} }"
	assert t2.short_str() == "{ .ident, '${text_want}' }"

	assert TokenKind.eq.str_for_ident() == '__eq__'
}

fn test_is() {
	assert TokenKind.plus.@is(.op)
	assert !TokenKind.ident.@is(.op)

	assert TokenKind.assign.@is(.assign_op)
	assert TokenKind.assign.@is(.op)
	assert !TokenKind.ident.@is(.assign_op)

	assert TokenKind.eq.@is(.comparsion_op)
	assert TokenKind.eq.@is(.op)
	assert !TokenKind.ident.@is(.comparsion_op)

	assert TokenKind.eq.@is(.infix_op)
	assert TokenKind.eq.@is(.op)
	assert !TokenKind.ident.@is(.infix_op)

	assert TokenKind.not.@is(.prefix_op)
	assert TokenKind.not.@is(.op)
	assert !TokenKind.ident.@is(.prefix_op)

	assert TokenKind.plusplus.@is(.postfix_op)
	assert TokenKind.plusplus.@is(.op)
	assert !TokenKind.ident.@is(.postfix_op)

	assert TokenKind.bool_literal.@is(.literal)
	assert !TokenKind.ident.@is(.literal)
	assert TokenKind.key_if.@is(.keyword)
	assert !TokenKind.ident.@is(.keyword)
}
