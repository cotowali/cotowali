module id

import rand
import math

pub interface IDObject {
mut:
	id u64
}

pub fn assign_auto_id(mut object IDObject) {
	object.id = rand.u64n(math.max_u64 - 1) + 1
}

pub fn clear_id(mut object IDObject) {
	object.id = 0
}
