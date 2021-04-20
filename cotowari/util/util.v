module util

pub fn @in<T>(v T, low T, high T) bool {
	return low <= v && v <= high
}

pub fn in2<T>(v T, low1 T, high1 T, low2 T, high2 T) bool {
	return (low1 <= v && v <= high1) || (low2 <= v && v <= high2)
}

pub fn escape(s string, targets []string) string {
	s2 := s.replace('\\', '\\\\')
	mut reps := []string{cap: targets.len * 2}
	for v in targets {
		reps << v
		reps << '\\' + v
	}
	return s2.replace_each(reps)
}
