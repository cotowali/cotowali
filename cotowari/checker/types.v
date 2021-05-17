module checker

import cotowari.symbols { TypeSymbol }
import cotowari.source { Pos }

struct TypeCheckingConfig {
	want       TypeSymbol [required]
	want_label string = 'expected'
	got        TypeSymbol [required]
	got_label  string = 'found'
	pos        Pos        [required]
}

fn (mut c Checker) check_types(v TypeCheckingConfig) ? {
	if v.want.typ != v.got.typ {
		m1 := '`$v.want.name` ($v.want_label)'
		m2 := '`$v.got.name` ($v.got_label)'
		c.error('mismatched types: $m1 and $m2', v.pos)
		return none
	}
	return
}
