module symbols

fn test_fn_signature() ? {
	mut s := new_global_scope()
	f1 := s.register_type(
		name: 'f1'
		info: FunctionTypeInfo{
			args: [builtin_type(.int), builtin_type(.bool)]
		}
	) ?
	f2 := s.register_type(
		name: 'f2'
		info: FunctionTypeInfo{
			args: [builtin_type(.int), builtin_type(.bool)]
			ret: builtin_type(.int)
		}
	) ?
	assert f1.fn_signature() ? == 'fn (int, bool) void'
	assert f2.fn_signature() ? == 'fn (int, bool) int'
	if _ := s.must_lookup_type(builtin_type(.int)).fn_signature() {
		assert false
	}
}
