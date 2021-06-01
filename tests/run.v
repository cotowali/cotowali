import os
import rand
import term
import v.util { color_compare_strings, find_working_diff_command }

enum FileSuffix {
	ri
	err
	todo
	out
}

fn suffix(s FileSuffix) string {
	return match s {
		.ri { '.ri' }
		.err { '_err' }
		.todo { '.todo' }
		.out { '.out' }
	}
}

fn is_err_test_file(f string) bool {
	name := f.trim_suffix(suffix(.ri)).trim_suffix(suffix(.todo))
	return name.ends_with(suffix(.err)) || name == 'error'
}

fn is_todo_test_file(f string) bool {
	return f.trim_suffix(suffix(.ri)).ends_with(suffix(.todo))
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
			res << (os.ls(path) or { panic(err) }).map(os.join_path(path, it)).filter(is_target_file)
		} else if is_target_file(path) {
			res << path
		}
	}
	return res
}

struct Ric {
	source string [required]
	bin    string [required]
}

enum RicCommand {
	compile
	run
}

fn (ric Ric) compile() ? {
	res := os.execute('v -cg $ric.source -o $ric.bin')
	if res.exit_code != 0 {
		return error_with_code(res.output, res.exit_code)
	}
	return
}

fn (ric Ric) execute(c RicCommand, file string) os.Result {
	return match c {
		.compile { os.execute('$ric.bin $file') }
		.run { os.execute('$ric.bin run $file') }
	}
}

fn (ric Ric) new_test_case(path string) TestCase {
	out := out_path(path)
	return {
		ric: ric
		path: path
		out_path: out
		is_err_test: is_err_test_file(path)
		is_todo_test: is_todo_test_file(path)
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
	ric Ric
mut:
	path         string     [required]
	out_path     string     [required]
	is_err_test  bool       [required]
	is_todo_test bool       [required]
	result       TestResult

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
		t.ric.execute(.compile, t.path)
	} else {
		t.ric.execute(.run, t.path)
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
	indent := ' '.repeat(2)
	format_output := fn (text string) string {
		indent := ' '.repeat(4)
		return if text.len == 0 {
			'${indent}__EMPTY__'
		} else {
			text.split_into_lines().map('$indent$it').join('\n')
		}
	}

	mut lines := [
		'${term.fail_message('[FAIL]')} $file',
		'${indent}exit_code: $t.exit_code',
		'${indent}output:',
		format_output(t.output),
		'${indent}expected:',
		format_output(t.expected),
	]
	if diff_cmd := find_working_diff_command() {
		diff := color_compare_strings(diff_cmd, rand.ulid(), t.expected, t.output)
		lines << [
			'${indent}diff:',
			diff.split_into_lines().map(indent.repeat(2) + it).join('\n'),
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
	ric_dir := os.join_path(dir, 'cmd/ric')
	sources := get_sources(paths)

	ric := Ric{
		source: ric_dir
		bin: os.join_path(ric_dir, 'ric')
	}

	ric.compile() or {
		eprintln([
			'${term.fail_message('ERROR')} Faild to compile ric',
			'    exit_code: $err.code',
			'    output:',
			err.msg.split_into_lines().map(' '.repeat(8) + it).join('\n'),
		].join('\n'))
		return false
	}

	mut ok := true
	for path in sources {
		mut t := ric.new_test_case(path)
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
