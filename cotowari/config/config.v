module config

pub enum Backend {
	sh
	dash
	bash
	zsh
	powershell
}

[heap]
pub struct Config {
pub mut:
	backend Backend = .sh
}

pub fn new_config() &Config {
	return {}
}
