module source

pub type Letter = string // utf-8 char

pub fn (c Letter) is_whitespace() bool {
	return (c.len == 1 && c[0].is_space() && c[0] !in [`\n`, `\r`]) || c == '　'
}
