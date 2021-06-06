module context

import cotowari.config { Config }

pub struct Context {
pub:
	config Config
}

pub fn new_context(config Config) &Context {
	return &Context{}
}

pub fn new_default_context() &Context {
	return new_context({})
}
