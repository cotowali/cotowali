module context

import cotowari.config { Config }
import cotowari.symbols { Scope, new_global_scope }
import cotowari.source { Source }

[heap]
pub struct Context {
pub:
	config       Config
	global_scope &Scope
pub mut:
	sources map[string]&Source
}

pub fn new_context(config Config) &Context {
	return &Context{
		global_scope: new_global_scope()
	}
}

pub fn new_default_context() &Context {
	return new_context({})
}
