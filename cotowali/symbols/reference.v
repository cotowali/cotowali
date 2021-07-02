module symbols

import cotowali.errors { unreachable }

pub struct ReferenceTypeInfo {
pub:
	target Type
}

fn (info ReferenceTypeInfo) typename(s &Scope) string {
	return '&${s.must_lookup_type(info.target)}'
}

pub fn (mut s Scope) lookup_or_register_reference_type(info ReferenceTypeInfo) TypeSymbol {
	return s.lookup_or_register_type(name: info.typename(s), info: info)
}

pub fn (s Scope) lookup_reference_type(info ReferenceTypeInfo) ?TypeSymbol {
	return s.lookup_type(info.typename(s))
}

pub fn (s Scope) must_lookup_reference_type(info ReferenceTypeInfo) TypeSymbol {
	return s.lookup_reference_type(info) or { panic(unreachable()) }
}
