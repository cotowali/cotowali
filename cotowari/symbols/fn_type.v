module symbols

import cotowari.errors { unreachable }

pub struct FunctionTypeInfo {
	args []Type
	ret  Type = builtin_type(.void)
}

fn (f FunctionTypeInfo) signature(s &Scope) string {
	args_str := f.args.map(s.must_lookup_type(it).name).join(', ')
	return 'fn ($args_str) ${s.must_lookup_type(f.ret).name}'
}

pub fn (t TypeSymbol) fn_signature() ?string {
	return if t.info is FunctionTypeInfo {
		t.info.signature(t.scope() or { panic(unreachable) })
	} else {
		none
	}
}

pub fn (mut s Scope) lookup_or_register_fn_type(info FunctionTypeInfo) TypeSymbol {
	typename := info.signature(s)
	return s.lookup_or_register_type(name: typename, info: info)
}
