module token

import cotowari.source { none_pos, pos }

fn test_eq() {
	t := Token{.unknown, 'text', pos(i: 10)}

	assert t == Token{
		...t
		pos: none_pos()
	}
	assert t != Token{
		...t
		pos: pos({})
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
	assert t2.str() == "Token{ .ident, '$text_want', $p }"
	assert t2.short_str() == "{ .ident, '$text_want' }"
}

fn test_is() {
	assert TokenKind.plus.@is(.op)
	assert !TokenKind.ident.@is(.op)
	assert TokenKind.eq.@is(.comparsion_op)
	assert !TokenKind.ident.@is(.comparsion_op)
	assert TokenKind.eq.@is(.infix_op)
	assert !TokenKind.ident.@is(.infix_op)
	assert TokenKind.not.@is(.prefix_op)
	assert !TokenKind.ident.@is(.prefix_op)
	assert TokenKind.plus_plus.@is(.postfix_op)
	assert !TokenKind.ident.@is(.postfix_op)
	assert TokenKind.bool_lit.@is(.literal)
	assert !TokenKind.ident.@is(.literal)
	assert TokenKind.key_if.@is(.keyword)
	assert !TokenKind.ident.@is(.keyword)
}
