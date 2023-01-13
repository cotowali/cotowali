// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module context

import cotowali.config { Config }
import cotowali.symbols { Scope, new_global_scope }
import cotowali.source { Source }
import cotowali.errors { ErrorManager }
import cotowali.compiler_directives { CompilerSymbolTable, new_compiler_symbol_table }

[heap]
pub struct Context {
pub:
	global_scope &Scope = unsafe { 0 }
pub mut:
	config           Config
	builtin_source   &Source = unsafe { 0 }
	testing_source   &Source = unsafe { 0 }
	sources          map[string]&Source
	errors           ErrorManager
	compiler_symbols CompilerSymbolTable
}

pub fn new_context(config Config) &Context {
	return &Context{
		global_scope: new_global_scope()
		config: config
		compiler_symbols: new_compiler_symbol_table(config)
	}
}

pub fn new_default_context() &Context {
	return new_context(Config{})
}

[inline]
pub fn (ctx &Context) builtin_loaded() bool {
	return !isnil(ctx.builtin_source)
}

[inline]
pub fn (ctx &Context) testing_loaded() bool {
	return !isnil(ctx.testing_source)
}
