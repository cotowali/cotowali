module util

import rand
import math

pub fn auto_id() u64 {
	return rand.u64n(math.max_u64 - 1) + 1
}
