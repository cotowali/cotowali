module config

pub enum Backend {
	sh
	dash
	bash
	zsh
	powershell
}

pub struct Config {
pub mut:
	backend Backend = .sh
	no_emit bool
	indent  string = '  '
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
