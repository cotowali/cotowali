module scope

import vash.util { auto_id }

pub struct TypeSymbol {
pub mut:
	id u64
pub:
	name string
}

pub fn new_type_symbol(name string) TypeSymbol {
	return TypeSymbol {
		id: auto_id()
		name: name
	}
}

[inline]
fn ts(sym TypeSymbol) TypeSymbol {
	return sym
}

pub const (
	unknown_type = ts(id: 1, name: 'unknown')
)
