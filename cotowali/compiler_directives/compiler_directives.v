// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module compiler_directives

import cotowali.config { Config }

pub enum CompilerDirectiveKind {
	error
	warning
	define
	undef
	if_
	else_
	endif
}

pub fn (k CompilerDirectiveKind) str() string {
	return match k {
		.error { '#error' }
		.warning { '#warning' }
		.define { '#define' }
		.undef { '#undef' }
		.if_ { '#if' }
		.else_ { '#else' }
		.endif { '#endif' }
	}
}

pub fn compiler_directive_kind_from_name(name string) ?CompilerDirectiveKind {
	match name {
		'error' { return .error }
		'warning' { return .warning }
		'define' { return .define }
		'undef' { return .undef }
		'if' { return .if_ }
		'else' { return .else_ }
		'endif' { return .endif }
		else { return error('unknown compiler directive `#$name`') }
	}
}

pub fn unexpected_compiler_directive(k CompilerDirectiveKind) string {
	return 'unexpected compiler directive $k'
}

pub fn missing_if_directive(k CompilerDirectiveKind) string {
	return unexpected_compiler_directive(k) + ' (missing #if)'
}

pub fn missing_endif_directive() string {
	return 'missing #endif'
}

type CompilerSymbolValue = string

fn (v CompilerSymbolValue) bool() bool {
	return v !in ['false', 'False', 'FALSE', '0', '']
}

pub struct CompilerSymbolTable {
mut:
	symbols map[string]CompilerSymbolValue
}

pub fn new_compiler_symbol_table(config Config) CompilerSymbolTable {
	mut table := CompilerSymbolTable{}
	match config.backend {
		.sh {
			table.define('sh')
		}
		.dash {
			table.define('sh')
			table.define('dash')
		}
		.bash {
			table.define('sh')
			table.define('bash')
		}
		.zsh {
			table.define('sh')
			table.define('zsh')
		}
		.pwsh {
			table.define('pwsh')
			table.define('powershell')
		}
	}
	if config.feature.has(.interactive) {
		table.define('lish')
	}
	if config.is_test {
		table.define('test')
	}
	return table
}

pub fn (mut table CompilerSymbolTable) define_with_value(name string, value string) {
	table.symbols[name] = value
}

pub fn (mut table CompilerSymbolTable) define(name string) {
	table.define_with_value(name, '1')
}

pub fn (mut table CompilerSymbolTable) undef(name string) {
	table.symbols.delete(name)
}

pub fn (mut table CompilerSymbolTable) has(name string) bool {
	return name in table.symbols
}

pub fn (mut table CompilerSymbolTable) get(name string) CompilerSymbolValue {
	return table.symbols[name]
}

pub fn (mut table CompilerSymbolTable) get_bool(name string) bool {
	if !table.has(name) {
		return false
	}
	return table.get(name).bool()
}
