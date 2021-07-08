module lexer

const (
	table_for_one_char_symbols = map{
		`(`: k(.l_paren)
		`)`: k(.r_paren)
		`{`: k(.l_brace)
		`}`: k(.r_brace)
		`[`: k(.l_bracket)
		`]`: k(.r_bracket)
		`<`: k(.lt)
		`>`: k(.gt)
		`#`: k(.hash)
		`+`: k(.plus)
		`-`: k(.minus)
		`*`: k(.mul)
		`/`: k(.div)
		`%`: k(.mod)
		`&`: k(.amp)
		`=`: k(.assign)
		`!`: k(.not)
		`,`: k(.comma)
		`.`: k(.dot)
	}

	table_for_two_chars_symbols = map{
		'++': k(.plus_plus)
		'--': k(.minus_minus)
		'&&': k(.logical_and)
		'||': k(.logical_or)
		'==': k(.eq)
		'!=': k(.ne)
		'<=': k(.le)
		'>=': k(.ge)
		'|>': k(.pipe)
	}

	table_for_three_chars_symbols = map{
		'...': k(.dotdotdot)
	}

	table_for_keywords = map{
		'as':      k(.key_as)
		'assert':  k(.key_assert)
		'var':     k(.key_var)
		'if':      k(.key_if)
		'else':    k(.key_else)
		'for':     k(.key_for)
		'in':      k(.key_in)
		'fn':      k(.key_fn)
		'return':  k(.key_return)
		'decl':    k(.key_decl)
		'require': k(.key_require)
		'struct':  k(.key_struct)
		'while':   k(.key_while)
		'yield':   k(.key_yield)
		'true':    k(.bool_lit)
		'false':   k(.bool_lit)
	}
)
