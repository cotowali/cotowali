module symbols

pub struct ArrayTypeInfo {
	elem Type
}

pub fn (mut s Scope) lookup_or_register_array_type(info ArrayTypeInfo) TypeSymbol {
	elem_ts := s.must_lookup_type(info.elem)
	typename := '[]$elem_ts.name'
	return s.lookup_or_register_type(name: typename, info: info)
}
