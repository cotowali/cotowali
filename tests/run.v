import os

const skip_list = ['nothing']

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

struct TestResult {
mut:
	file        string [required]
	is_err_test bool   [required]
	ok          bool   [required]
	exit_code   int    [required]
	output      string [required]
	expected    string [required]
}

fn (result TestResult) print_fail_info() {
	indent := ' '.repeat(2)
	format_output := fn (text string) string {
		indent := ' '.repeat(4)
		return if text.len == 0 {
			'${indent}__EMPTY__'
		} else {
			text.split_into_lines().map('$indent$it').join('\n')
		}
	}
	println('[FAIL] $result.file')
	println('${indent}exit_code: $result.exit_code')
	println('${indent}output:')
	println(format_output(result.output))
	println('${indent}expected:')
	println(format_output(result.expected))
	println('')
}

fn run() bool {
	dir := os.real_path(@VMODROOT)
	ric_dir := os.join_path(dir, 'cmd/ric')
	bin := os.join_path(ric_dir, 'ric')
	examples_dir := os.join_path(dir, 'examples')
	tests_dir := os.join_path(dir, 'tests')
	sources := get_sources(examples_dir, tests_dir)
	assert os.execute('v $ric_dir').exit_code == 0

	mut ok := true
	for path in sources {
		out_path := path.trim_suffix(os.file_ext(path)) + '.out'
		is_err_test := path.ends_with('_err.ri')

		cmd_result := os.execute(if is_err_test { '$bin $path' } else { '$bin run $path' })
		expected := os.read_file(out_path) or { '' }
		output := cmd_result.output
		exit_code := cmd_result.exit_code

		mut case_ok := true
		$if fix ? {
			if output != expected {
				os.write_file(out_path, output) or { panic(err) }
			}
			case_ok = true
		} $else {
			case_ok = output == expected
				&& (if is_err_test { exit_code != 0 } else { exit_code == 0 })
		}
		result := TestResult{
			file: os.join_path(os.base(os.dir(path)), os.base(path))
			is_err_test: is_err_test
			ok: case_ok
			exit_code: exit_code
			output: output
			expected: expected
		}
		if !result.ok {
			ok = false
			result.print_fail_info()
		}
	}
	return ok
}

fn main() {
	exit(if run() { 0 } else { 1 })
}
