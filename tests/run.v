import os
import rand
import term
import v.util { color_compare_strings, find_working_diff_command }

fn indent(n int) string {
	return '  '.repeat(n)
}

fn indent_each_lines(n int, s string) string {
	return s.split_into_lines().map(indent(n) + it).join('\n')
}

enum FileSuffix {
	ri
	err
	todo
	out
	noemit
}

fn suffix(s FileSuffix) string {
	return match s {
		.ri { '.ri' }
		.err { '.err' }
		.todo { '.todo' }
		.out { '.out' }
		.noemit { '.noemit' }
	}
}

fn is_err_test_file(f string) bool {
	name := f.trim_suffix(suffix(.ri)).trim_suffix(suffix(.todo))
	return name.ends_with(suffix(.err)) || name == 'error'
}

fn is_todo_test_file(f string) bool {
	return f.trim_suffix(suffix(.ri)).ends_with(suffix(.todo))
}

fn is_noemit_test_file(f string) bool {
	return f.trim_suffix(suffix(.ri)).trim_suffix(suffix(.todo)).ends_with(suffix(.noemit))
}

fn out_path(f string) string {
	return f.trim_suffix(suffix(.ri)) + suffix(.out)
}

const skip_list = ['nothing']

fn is_target_file(s string) bool {
	for skip in skip_list {
		if s.ends_with(skip) {
			return false
		}
	}
	return s.ends_with(suffix(.ri))
}

fn get_sources(paths []string) []string {
	mut res := []string{}
	for path in paths {
		if os.is_dir(path) {
			sub_paths := os.ls(path) or { panic(err) }
			res << get_sources(sub_paths.map(os.join_path(path, it)))
		} else if is_target_file(path) {
			res << path
		}
	}
	return res
}

struct Lic {
	source string [required]
	bin    string [required]
}

enum LicCommand {
	compile
	noemit
	run
}

fn (lic Lic) compile() ? {
	res := os.execute('v -cg $lic.source -o $lic.bin')
	if res.exit_code != 0 {
		return error_with_code(res.output, res.exit_code)
	}
	return
}

fn (lic Lic) execute(c LicCommand, file string) os.Result {
	return match c {
		.compile { os.execute('$lic.bin $file') }
		.noemit { os.execute('$lic.bin --no-emit $file') }
		.run { os.execute('$lic.bin run $file') }
	}
}

fn (lic Lic) new_test_case(path string) TestCase {
	out := out_path(path)
	return {
		lic: lic
		path: path
		out_path: out
		is_err_test: is_err_test_file(path)
		is_todo_test: is_todo_test_file(path)
		is_noemit_test: is_noemit_test_file(path)
		expected: os.read_file(out) or { '' }
	}
}

enum TestResult {
	ok
	failed
	fixed
	todo
}

struct TestCase {
	lic Lic
mut:
	path           string     [required]
	out_path       string     [required]
	is_err_test    bool       [required]
	is_todo_test   bool       [required]
	is_noemit_test bool       [required]
	result         TestResult

	exit_code int
	expected  string [required]
	output    string
}

fn fix_todo(f string, s FileSuffix) {
	base := f.trim_suffix(suffix(s)).trim_suffix(suffix(.todo))
	os.mv(f, base + suffix(s)) or { panic(err) }
}

fn (mut t TestCase) run() {
	result := if t.is_err_test {
		t.lic.execute(.compile, t.path)
	} else {
		t.lic.execute(.run, t.path)
	}
	t.output = result.output
	t.exit_code = result.exit_code

	correct_exit_code := if t.is_err_test { t.exit_code != 0 } else { t.exit_code == 0 }
	if t.is_todo_test {
		t.result = .todo
	} else {
		t.result = if t.output == t.expected && correct_exit_code {
			TestResult.ok
		} else {
			TestResult.failed
		}
	}
	$if fix ? {
		if correct_exit_code {
			if t.is_todo_test {
				if t.output == t.expected {
					fix_todo(t.path, .ri)
					fix_todo(t.out_path, .out)
					t.result = .fixed
				}
			} else if t.output != t.expected {
				os.write_file(t.out_path, t.output) or { panic(err) }
				t.result = .fixed
			}
		}
	}
}

fn (t TestCase) failed_result(file string) string {
	format_output := fn (text string) string {
		indent := ' '.repeat(4)
		return if text.len == 0 { '${indent}__EMPTY__' } else { indent_each_lines(1, text) }
	}

	mut lines := [
		'${term.fail_message('[FAIL]')} $file',
		'${indent(1)}exit_code: $t.exit_code',
		'${indent(1)}output:',
		format_output(t.output),
		'${indent(1)}expected:',
		format_output(t.expected),
	]
	if diff_cmd := find_working_diff_command() {
		diff := color_compare_strings(diff_cmd, rand.ulid(), t.expected, t.output)
		lines << [
			'${indent}diff:',
			indent_each_lines(2, diff),
		]
	}

	return lines.map(it + '\n').join('')
}

fn (t TestCase) result() string {
	file := os.join_path(os.base(os.dir(t.path)), os.base(t.path))
	return match t.result {
		.ok { '${term.ok_message('[ OK ]')} $file' }
		.fixed { '${term.ok_message('[ OK ]')} $file (FIXED)' }
		.todo { '${term.warn_message('[TODO]')} $file' }
		.failed { t.failed_result(file) }
	}
}

fn run(paths []string) bool {
	dir := os.real_path(@VMODROOT)
	lic_dir := os.join_path(dir, 'cmd/lic')
	sources := get_sources(paths)

	lic := Lic{
		source: lic_dir
		bin: os.join_path(lic_dir, 'lic')
	}

	lic.compile() or {
		eprintln([
			'${term.fail_message('ERROR')} Faild to compile lic',
			'    exit_code: $err.code',
			'    output:',
			indent_each_lines(2, err.msg),
		].join('\n'))
		return false
	}

	mut ok := true
	for path in sources {
		mut t := lic.new_test_case(path)
		t.run()
		ok = ok && t.result != .failed
		println(t.result())
	}
	return ok
}

fn main() {
	if ['--help', '-h', 'help'].any(it in os.args) {
		println('Usage: v run tests/run.v [test.ri|tests]...')
		return
	}
	paths := if os.args.len > 1 {
		os.args[1..]
	} else {
		['examples', 'tests'].map(os.join_path(@VMODROOT, it))
	}
	exit(if run(paths) { 0 } else { 1 })
}
