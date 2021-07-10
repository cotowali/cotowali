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
		'+=': k(.plus_assign)
		'-=': k(.minus_assign)
		'*=': k(.mul_assign)
		'/=': k(.div_assign)
		'%=': k(.mod_assign)
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
		'true':    k(.bool_lit)
		'false':   k(.bool_lit)
		'as':      k(.key_as)
		'assert':  k(.key_assert)
		'decl':    k(.key_decl)
		'export':  k(.key_export)
		'else':    k(.key_else)
		'fn':      k(.key_fn)
		'for':     k(.key_for)
		'if':      k(.key_if)
		'in':      k(.key_in)
		'require': k(.key_require)
		'return':  k(.key_return)
		'struct':  k(.key_struct)
		'use':     k(.key_use)
		'var':     k(.key_var)
		'while':   k(.key_while)
		'yield':   k(.key_yield)
	}
)
