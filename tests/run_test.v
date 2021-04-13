import os

fn test_run() ? {
	dir := os.dir(@FILE)
	filter := fn (s string) bool {
		return s.ends_with('.ri')
	}
	sources := (os.ls(dir) ?).filter(filter).map(os.join_path(dir, it))
	assert os.execute('v cmd/ri').exit_code == 0
	for path in sources {
		println('$path')
		out_path := path.trim_suffix(os.file_ext(path)) + '.out'
		expected := os.read_file(out_path) ?
		println('FILE: $path')
		if path.ends_with('_err.ri') {
			result := os.execute('./cmd/ri/ri $path')
			assert result.exit_code != 0
			$if fix ? {
				if result.output != expected {
					os.write_file(out_path, result.output) ?
				}
			} $else {
				assert result.output == expected
			}
		} else {
			result := os.execute('./cmd/ri/ri run $path')
			assert result.exit_code == 0
			$if fix ? {
				if result.output != expected {
					os.write_file(out_path, result.output) ?
				}
			} $else {
				assert result.output == expected
			}
		}
	}
}
