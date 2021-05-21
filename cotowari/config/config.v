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
	return &Config{}
}

pub fn backend_from_str(s string) ?Backend {
	match s {
		'sh' { return .sh }
		'dash' { return .dash }
		'bash' { return .bash }
		'zsh' { return .zsh }
		else { return error('unknown backend `$s`') }
	}
}
