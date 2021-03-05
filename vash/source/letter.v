module source

pub type Letter = string // utf-8 char

pub fn (c Letter) rune() rune {
	return rune(c.utf32_code())
}

pub enum LetterClass {
	whitespace
}

pub fn (c Letter) @is(class LetterClass) bool {
	return match class {
		.whitespace { (c.len == 1 && c[0].is_space() && c[0] !in [`\n`, `\r`]) || c == '　' }
	}
}
