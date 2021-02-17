module source

type Letter = string

fn (c Letter) is_whitespace() bool {
	return (c.len == 1 && c[0].is_space() && c[0] !in [`\n`, `\r`]) || c == '　'
}
