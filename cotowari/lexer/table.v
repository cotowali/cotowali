module lexer

const (
	table_for_one_char_symbols = map{
		`(`: k(.l_paren)
		`)`: k(.r_paren)
		`{`: k(.l_brace)
		`}`: k(.r_brace)
		`[`: k(.l_bracket)
		`]`: k(.r_bracket)
		`<`: k(.op_lt)
		`>`: k(.op_gt)
		`#`: k(.hash)
		`+`: k(.op_plus)
		`-`: k(.op_minus)
		`*`: k(.op_mul)
		`/`: k(.op_div)
		`%`: k(.op_mod)
		`&`: k(.amp)
		`|`: k(.op_pipe)
		`=`: k(.op_assign)
		`!`: k(.op_not)
		`,`: k(.comma)
		`.`: k(.dot)
	}

	table_for_two_chars_symbols = map{
		'++': k(.op_plus_plus)
		'--': k(.op_minus_minus)
		'&&': k(.op_logical_and)
		'||': k(.op_logical_or)
		'==': k(.op_eq)
		'!=': k(.op_ne)
		'<=': k(.op_le)
		'>=': k(.op_ge)
	}

	table_for_three_chars_symbols = map{
		'...': k(.dotdotdot)
	}

	table_for_keywords = map{
		'as':      k(.key_as)
		'assert':  k(.key_assert)
		'let':     k(.key_let)
		'if':      k(.key_if)
		'else':    k(.key_else)
		'for':     k(.key_for)
		'in':      k(.key_in)
		'fn':      k(.key_fn)
		'return':  k(.key_return)
		'decl':    k(.key_decl)
		'require': k(.key_require)
		'struct':  k(.key_struct)
		'true':    k(.bool_lit)
		'false':   k(.bool_lit)
	}
)
