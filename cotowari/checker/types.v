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
		c.error('mismatch type: `$v.want.name` ($v.want_label), `$v.got.name` ($v.got_label)',
			v.pos)
		return none
	}
	return
}
