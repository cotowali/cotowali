module symbols

fn test_register_or_find_array_type() {
	mut s := new_global_scope()
	n := s.type_symbols.keys().len
	int_array := s.lookup_or_register_array_type(elem: builtin_type(.int))
	assert int_array.name == '[]int'
	assert s.type_symbols.keys().len == n + 1

	int_array2 := s.lookup_or_register_array_type(elem: builtin_type(.int))
	assert int_array2.name == '[]int'
	assert s.type_symbols.keys().len == n + 1
}
