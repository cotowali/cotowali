module symbols

pub fn (mut s Scope) register_builtin() {
	for ts in builtin.type_symbols {
		s.must_register_type(ts)
	}
}
