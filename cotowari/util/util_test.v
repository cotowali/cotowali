module util

fn test_in() {
	assert @in(0, 0, 1)
	assert @in(1, 0, 1)
	assert !@in(2, 0, 1)

	assert @in('c', 'a', 'z')

	assert in2('c', '0', '2', 'a', 'c')
	assert in2('1', '0', '2', 'a', 'c')
	assert !in2('9', '0', '2', 'a', 'c')
	assert !in2('z', '0', '2', 'a', 'c')
}

fn test_escape() {
	bs := '\\'
	assert escape(bs, []) == bs + bs
	assert escape('abc', ['a', 'b', 'd']) == '${bs}a${bs}bc'
}

struct Ref {
mut:
	ref &string = 0
}

fn (v Ref) opt() ?&string {
	return nil_to_none(v.ref)
}

fn test_nil_to_none() {
	mut v := Ref{}
	if _ := v.opt() {
		assert false
	}
	s := 'x'
	v.ref = &s
	assert v.opt() or { assert false } == &s
}
