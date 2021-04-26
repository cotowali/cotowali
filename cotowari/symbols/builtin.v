module symbols

pub const (
	unknown_type = Type{
		id: 1
		name: 'unknown'
		info: UnknownTypeInfo{}
	}
	int_type     = Type{
		id: 2
		name: 'int'
		info: PrimitiveTypeInfo{}
	}
	string_type  = Type{
		id: 3
		name: 'string'
		info: PrimitiveTypeInfo{}
	}
	bool_type    = Type{
		id: 4
		name: 'bool'
		info: PrimitiveTypeInfo{}
	}
)
