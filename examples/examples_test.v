module examples

import os { ls, dir, join_path }
import vash.compiler { new_compiler }
import vash.source

fn test_examples_success() ? {
	dir := dir(@FILE)
	files := (ls(dir) ?).filter(!it.ends_with('.v')).map(join_path(dir, it))
	mut ok := true
	for f in files {
		println(f)
		c := new_compiler(source.read_file(f)?)
		out := c.compile() or {
			dump(err)
			ok = false
			continue
		}
		assert out.len > 0
	}
	assert ok
}
