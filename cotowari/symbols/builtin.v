module symbols

import cotowari.errors { unreachable }

pub enum BuiltinTypeKey {
	unknown
	int
	string
	bool
}

pub fn builtin_type(key BuiltinTypeKey) Type {
	v := symbols.builtin_types[key] or { panic(unreachable) }
	return v
}

pub const (
	builtin_types = (fn () map[BuiltinTypeKey]Type {
		k := fn (k BuiltinTypeKey) BuiltinTypeKey {
			return k
		}
		return map{
			k(.unknown): Type{
				id: 1
				name: 'unknown'
				info: UnknownTypeInfo{}
			}
			k(.int):     Type{
				id: 2
				name: 'int'
				info: PrimitiveTypeInfo{}
			}
			k(.string):  Type{
				id: 3
				name: 'string'
				info: PrimitiveTypeInfo{}
			}
			k(.bool):    Type{
				id: 4
				name: 'bool'
				info: PrimitiveTypeInfo{}
			}
		}
	}())
)
