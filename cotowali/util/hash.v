module util

import hash

[inline]
fn sum64(data []byte) u64 {
	return hash.sum64(data, 0)
}
