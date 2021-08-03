// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module parser

import cotowali.context { new_default_context }
import cotowali.lexer { new_lexer }
import cotowali.source { new_source }

fn test_consume_token() {
	ctx := new_default_context()
	mut p := new_parser(new_lexer(new_source('', '0 1 2 3 4'), ctx))
	assert p.token(0).text == '0'
	assert p.token(1).text == '1'
	assert p.token(2).text == '2'

	p.consume()
	assert p.token(-1).text == '0'
	assert p.token(0).text == '1'
	assert p.token(1).text == '2'
	assert p.token(2).text == '3'

	p.consume()
	assert p.token(-1).text == '1'
	assert p.token(0).text == '2'
	assert p.token(1).text == '3'

	p.consume()
	p.consume()
	assert p.token(-1).text == '3'
	assert p.token(0).text == '4'
	assert p.token(1).kind == .eof
	assert p.token(2).kind == .eof
}
