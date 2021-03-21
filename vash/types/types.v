module types

struct TypeSymbol {
pub:
	name string
}

pub fn new_symbol(name string) TypeSymbol {
	return TypeSymbol {
		name: name
	}
}

pub const (
	unknown = new_symbol('unknown')
)
