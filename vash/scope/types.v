module scope

struct TypeSymbol {
pub:
	name string
}

pub fn new_type_symbol(name string) TypeSymbol {
	return TypeSymbol {
		name: name
	}
}

pub const (
	unknown_type = new_type_symbol('unknown')
)
