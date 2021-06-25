module context

import cotowari.config { Config }
import cotowari.symbols { Scope, new_global_scope }
import cotowari.source { Source }
import cotowari.errors { Errors }

[heap]
pub struct Context {
pub:
	config       Config
	global_scope &Scope
pub mut:
	std_source &Source = 0
	sources    map[string]&Source
	errors     Errors
}

pub fn new_context(config Config) &Context {
	return &Context{
		global_scope: new_global_scope()
		config: config
	}
}

pub fn new_default_context() &Context {
	return new_context({})
}

[inline]
pub fn (ctx &Context) std_loaded() bool {
	return !isnil(ctx.std_source)
}
