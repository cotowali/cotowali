import os

const skip_list = [
	'examples/hello.ri'
]

fn is_target_file(s string) bool {
	for skip in skip_list {
		if s.ends_with(skip) {
			return false
		}
	}
	return s.ends_with('.ri')
}

fn get_sources(dirs ...string) []string {
	mut res := []string{}
	for dir in dirs {
		res << (os.ls(dir) or { panic(err) }).map(os.join_path(dir, it)).filter(is_target_file)
	}
	return res
}

fn test_run() ? {
	dir := os.dir(@FILE)
	examples_dir := os.join_path(dir, 'examples')
	tests_dir := os.join_path(dir, 'tests')
	sources := get_sources(examples_dir, tests_dir)
	assert os.execute('v cmd/ric').exit_code == 0
	for path in sources {
		println('$path')
		out_path := path.trim_suffix(os.file_ext(path)) + '.out'
		expected := os.read_file(out_path) or { '' }
		println('FILE: $path')
		if path.ends_with('_err.ri') {
			result := os.execute('./cmd/ric/ric $path')
			assert result.exit_code != 0
			$if fix ? {
				if result.output != expected {
					os.write_file(out_path, result.output) ?
				}
			} $else {
				assert result.output == expected
			}
		} else {
			result := os.execute('./cmd/ric/ric run $path')
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
