module source

import vash.util { @in, in2 }

pub type Char = string // utf-8 char

pub fn (c Char) rune() rune {
	return rune(c.utf32_code())
}

pub enum CharClass {
	whitespace
	alphabet
	digit
	hex_digit
	oct_digit
	binary_digit
}

pub fn (c Char) @is(class CharClass) bool {
	return match class {
		.whitespace { (c.len == 1 && c[0].is_space() && c[0] !in [`\n`, `\r`]) || c == '　' }
		.alphabet { in2(c[0], `a`, `z`, `A`, `Z`) }
		.digit { @in(c[0], `0`, `9`) }
		.hex_digit{ c.@is(.digit) || in2(c[0], `a`, `f`, `A`, `F`) }
		.oct_digit { @in(c[0], `0`, `7`) }
		.binary_digit { @in(c[0], `0`, `1`) }
	}
}
