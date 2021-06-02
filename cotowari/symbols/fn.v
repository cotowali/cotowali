module symbols

import cotowari.errors { unreachable }

pub struct FunctionTypeInfo {
pub:
	params       []Type
	ret          Type = builtin_type(.void)
	is_varargs   bool
	varargs_elem Type
}

pub fn (t TypeSymbol) fn_info() FunctionTypeInfo {
	if t.info is FunctionTypeInfo {
		return t.info
	} else {
		panic(unreachable)
	}
}

fn (f FunctionTypeInfo) signature(s &Scope) string {
	mut param_strs := []string{len: f.params.len}
	for i, param in f.params {
		name := s.must_lookup_type(param).name
		param_strs[i] = if f.is_varargs && i == f.params.len - 1 { '...$name' } else { name }
	}
	params_str := param_strs.join(', ')
	return 'fn ($params_str) ${s.must_lookup_type(f.ret).name}'
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

pub fn (s Scope) lookup_fn_type(info FunctionTypeInfo) ?TypeSymbol {
	typename := info.signature(s)
	return s.lookup_type(typename)
}

pub fn (mut s Scope) register_fn(name string, info FunctionTypeInfo) ?&Var {
	return s.register_var(name: name, typ: s.lookup_or_register_fn_type(info).typ)
}

fn (mut s Scope) must_register_fn(name string, info FunctionTypeInfo) &Var {
	return s.register_fn(name, info) or { panic(unreachable) }
}
