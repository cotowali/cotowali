#!v run

// TODO: cleanup (regex ?)

lines := read_lines('README.md') ?
mut i, mut begin, mut end := 0, -1, -1
for i < lines.len {
	mut line := lines[i]
	if line.contains('## Example') {
		for i < lines.len {
			line = lines[i]
			if line.contains('```') {
				if begin == -1 {
					begin = i + 1
				} else {
					end = i
					break
				}
			}
			i++
		}
		break
	}
	i++
}

write_file('examples/readme_example.li', lines[begin..end].map(it + '\n').join('')) ?
