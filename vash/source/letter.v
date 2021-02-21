module source

pub type Letter = string // utf-8 char

pub fn (c Letter) is_whitespace() bool {
	return (c.len == 1 && c[0].is_space() && c[0] !in [`\n`, `\r`]) || c == '　'
}

pub fn (letters []Letter) str() string {
	mut len := 0
	for letter in letters {
		len += letter.len
	}
	s_buf := unsafe { malloc(len + 1) }
	mut s_i := 0
	for letter in letters {
		for c in letter as string {
			unsafe { s_buf[s_i] = c }
			s_i++
		}
	}
	unsafe {
		s_buf[len] = 0
		return s_buf.vstring_with_len(len)
	}
}
