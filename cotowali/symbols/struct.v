module symbols

pub struct StructTypeInfo {
pub:
	fields map[string]Type
}

fn (info StructTypeInfo) type_to_str(s &Scope) string {
	fields_str := info.fields.keys().map('$it ${s.must_lookup_type(info.fields[it]).name}').join(', ')
	return 'struct { $fields_str }'
}

pub fn (ts &TypeSymbol) struct_info() ?StructTypeInfo {
	return if ts.info is StructTypeInfo { ts.info } else { none }
}

pub fn (mut s Scope) register_struct_type(name string, info StructTypeInfo) ?&TypeSymbol {
	return s.register_type(name: name, info: info)
}
