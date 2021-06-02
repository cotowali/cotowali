module token

import cotowari.source { none_pos, pos }

fn test_eq() {
	t := Token{.unknown, 'text', pos(i: 10)}

	assert t == Token{
		...t
		pos: none_pos
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
	assert Token{.ident, 'a', none_pos}.str() == "Token{ .ident, 'a', none }"

	p := pos(i: 0)
	text, text_want := '\n\r\\', r'\n\r\\'
	assert Token{.ident, text, p}.str() == "Token{ .ident, '$text_want', $p }"
}

fn test_is() {
	assert TokenKind.op_plus.@is(.op)
	assert !TokenKind.ident.@is(.op)
	assert TokenKind.op_eq.@is(.comparsion_op)
	assert !TokenKind.ident.@is(.comparsion_op)
	assert TokenKind.op_eq.@is(.infix_op)
	assert !TokenKind.ident.@is(.infix_op)
	assert TokenKind.op_not.@is(.prefix_op)
	assert !TokenKind.ident.@is(.prefix_op)
	assert TokenKind.op_plus_plus.@is(.postfix_op)
	assert !TokenKind.ident.@is(.postfix_op)
	assert TokenKind.bool_lit.@is(.literal)
	assert !TokenKind.ident.@is(.literal)
	assert TokenKind.key_if.@is(.keyword)
	assert !TokenKind.ident.@is(.keyword)
}
