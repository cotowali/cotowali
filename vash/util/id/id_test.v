module id

struct TestIDObj {
pub mut:
	id u64
}

fn test_assign_auto_id() {
	mut v := TestIDObj{}
	assert v.id == 0
	assign_auto_id(mut v)
	assert v.id > 0
	clear_id(mut v)
	assert v.id == 0
}
