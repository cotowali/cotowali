// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lexer

const (
	table_for_one_char_symbols = {
		`(`: tk(.l_paren)
		`)`: tk(.r_paren)
		`{`: tk(.l_brace)
		`}`: tk(.r_brace)
		`[`: tk(.l_bracket)
		`]`: tk(.r_bracket)
		`<`: tk(.lt)
		`>`: tk(.gt)
		`?`: tk(.question)
		`#`: tk(.hash)
		`+`: tk(.plus)
		`-`: tk(.minus)
		`*`: tk(.mul)
		`/`: tk(.div)
		`%`: tk(.mod)
		`&`: tk(.amp)
		`=`: tk(.assign)
		`!`: tk(.not)
		`,`: tk(.comma)
		`.`: tk(.dot)
		`:`: tk(.colon)
		`;`: tk(.eol)
	}

	table_for_two_chars_symbols = {
		'++': tk(.plusplus)
		'--': tk(.minusminus)
		'&&': tk(.logical_and)
		'||': tk(.logical_or)
		'**': tk(.pow)
		'+=': tk(.plus_assign)
		'-=': tk(.minus_assign)
		'*=': tk(.mul_assign)
		'/=': tk(.div_assign)
		'%=': tk(.mod_assign)
		'==': tk(.eq)
		'!=': tk(.ne)
		'<=': tk(.le)
		'>=': tk(.ge)
		'|>': tk(.pipe)
		'::': tk(.coloncolon)
	}

	table_for_three_chars_symbols = {
		'...': tk(.dotdotdot)
		'**=': tk(.pow_assign)
		'|>>': tk(.pipe_append)
	}

	table_for_keywords = {
		'as':       tk(.key_as)
		'assert':   tk(.key_assert)
		'break':    tk(.key_break)
		'continue': tk(.key_continue)
		'else':     tk(.key_else)
		'export':   tk(.key_export)
		'fn':       tk(.key_fn)
		'for':      tk(.key_for)
		'if':       tk(.key_if)
		'in':       tk(.key_in)
		'map':      tk(.key_map)
		'module':   tk(.key_module)
		'null':     tk(.key_null)
		'require':  tk(.key_require)
		'return':   tk(.key_return)
		'struct':   tk(.key_struct)
		'type':     tk(.key_type)
		'use':      tk(.key_use)
		'var':      tk(.key_var)
		'while':    tk(.key_while)
		'yield':    tk(.key_yield)
		'true':     tk(.bool_literal)
		'false':    tk(.bool_literal)
	}
)
