module util

pub fn @in<T>(v T, low T, high T) bool {
	return low <= v && v <= high
}

pub fn in2<T>(v T, low1 T, high1 T, low2 T, high2 T) bool {
	return (low1 <= v && v <= high1) || (low2 <= v && v <= high2)
}

pub struct AssertInfo {
	file string
	name string
	line string
	col string
}

pub fn @assert(cond bool, msg string, info AssertInfo) {
	$if !prod {
		if !cond {
			file, name, line, col := info.file, info.name, info.line, info.col
			mut text := 'assertion failed:'
			if file.len > 0 {
				text += 'file: $file'
			}
			if name.len > 0 {
				text += ' name: $name'
			}
			if line.len > 0 && col.len > 0{
				text += ' $line:$col'
			} else if line.len > 0 {
				text += ' line: $line'
			} else if col.len > 0 {
				text += ' col: $col'
			}
			text += ' $msg'
			panic(text)
		}
	}
}
