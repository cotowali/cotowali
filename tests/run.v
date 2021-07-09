import os
import rand
import term
import v.util { color_compare_strings, find_working_diff_command }
import time

fn indent(n int) string {
	return '  '.repeat(n)
}

fn indent_each_lines(n int, s string) string {
	return s.split_into_lines().map(indent(n) + it).join('\n')
}

enum FileSuffix {
	li
	err
	todo
	out
	noemit
}

fn suffix(s FileSuffix) string {
	return match s {
		.li { '.li' }
		.err { '.err' }
		.todo { '.todo' }
		.out { '.out' }
		.noemit { '.noemit' }
	}
}

fn is_err_test_file(f string) bool {
	name := f.trim_suffix(suffix(.li)).trim_suffix(suffix(.todo))
	return name.ends_with(suffix(.err)) || name == 'error'
}

fn is_todo_test_file(f string) bool {
	return f.trim_suffix(suffix(.li)).ends_with(suffix(.todo))
}

fn is_noemit_test_file(f string) bool {
	return f.trim_suffix(suffix(.li)).trim_suffix(suffix(.todo)).ends_with(suffix(.noemit))
}

fn out_path(f string) string {
	return f.trim_suffix(suffix(.li)) + suffix(.out)
}

const skip_list = ['nothing']

fn is_target_file(s string) bool {
	for skip in skip_list {
		if s.ends_with(skip) {
			return false
		}
	}
	return s.ends_with(suffix(.li))
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

enum TestResultStatus {
	ok
	failed
	fixed
	todo
}

struct TestResult {
mut:
	exit_code int
	output    string
	status    TestResultStatus
	elapsed   time.Duration
}

struct TestCase {
	lic Lic
mut:
	path           string     [required]
	out_path       string     [required]
	is_err_test    bool       [required]
	is_todo_test   bool       [required]
	is_noemit_test bool       [required]
	expected       string     [required]
	result         TestResult
}

fn fix_todo(f string, s FileSuffix) {
	base := f.trim_suffix(suffix(s)).trim_suffix(suffix(.todo))
	os.mv(f, base + suffix(s)) or { panic(err) }
}

fn (mut t TestCase) run() {
	mut sw := time.new_stopwatch({})
	sw.start()
	result := if t.is_err_test {
		t.lic.execute(.compile, t.path)
	} else if t.is_noemit_test {
		t.lic.execute(.noemit, t.path)
	} else {
		t.lic.execute(.run, t.path)
	}
	sw.stop()
	t.result.elapsed = sw.elapsed()
	t.result.output = result.output
	t.result.exit_code = result.exit_code

	correct_exit_code := if t.is_err_test {
		t.result.exit_code != 0
	} else {
		t.result.exit_code == 0
	}
	if t.is_todo_test {
		t.result.status = .todo
	} else {
		t.result.status = if t.result.output == t.expected && correct_exit_code {
			TestResultStatus.ok
		} else {
			TestResultStatus.failed
		}
	}

	$if fix ? {
		if correct_exit_code {
			if t.is_todo_test {
				if t.output == t.expected {
					fix_todo(t.path, .li)
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

fn (t TestCase) summary_message(file string) string {
	status := match t.result.status {
		.ok, .fixed { term.ok_message('[ OK ]') }
		.todo { term.warn_message('[TODO]') }
		.failed { term.fail_message('[FAIL]') }
	}
	elapsed_ms := f64(t.result.elapsed.microseconds()) / 1000.0
	msg := '$status ${elapsed_ms:6.2f} ms $file'
	return if t.result.status == .fixed { '$msg (FIXED)' } else { msg }
}

fn (t TestCase) failed_message(file string) string {
	format_output := fn (text string) string {
		indent := ' '.repeat(4)
		return if text.len == 0 { '${indent}__EMPTY__' } else { indent_each_lines(1, text) }
	}

	mut lines := [
		t.summary_message(file),
		'${indent(1)}exit_code: $t.result.exit_code',
		'${indent(1)}output:',
		format_output(t.result.output),
		'${indent(1)}expected:',
		format_output(t.expected),
	]
	if diff_cmd := find_working_diff_command() {
		diff := color_compare_strings(diff_cmd, rand.ulid(), t.expected, t.result.output)
		lines << [
			'${indent}diff:',
			indent_each_lines(2, diff),
		]
	}

	return lines.map(it + '\n').join('')
}

fn (t TestCase) result_message() string {
	file := os.join_path(os.base(os.dir(t.path)), os.base(t.path))
	return match t.result.status {
		.failed { t.failed_message(file) }
		else { t.summary_message(file) }
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
		ok = ok && t.result.status != .failed
		println(t.result_message())
	}
	return ok
}

fn main() {
	if ['--help', '-h', 'help'].any(it in os.args) {
		println('Usage: v run tests/run.v [test.li|tests]...')
		return
	}
	paths := if os.args.len > 1 {
		os.args[1..]
	} else {
		['examples', 'tests'].map(os.join_path(@VMODROOT, it))
	}
	exit(if run(paths) { 0 } else { 1 })
}
