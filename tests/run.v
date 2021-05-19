import os
import term

const skip_list = ['nothing']

fn is_target_file(s string) bool {
	for skip in skip_list {
		if s.ends_with(skip) {
			return false
		}
	}
	return s.ends_with('.ri')
}

fn get_sources(dirs []string) []string {
	mut res := []string{}
	for dir in dirs {
		res << (os.ls(dir) or { panic(err) }).map(os.join_path(dir, it)).filter(is_target_file)
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

fn (ric Ric) compile() os.Result {
	return os.execute('v $ric.source -o $ric.bin')
}

fn (ric Ric) execute(c RicCommand, file string) os.Result {
	return match c {
		.compile { os.execute('$ric.bin $file') }
		.run { os.execute('$ric.bin run $file') }
	}
}

fn (ric Ric) new_test_case(path string) TestCase {
	out_path := path.trim_suffix(os.file_ext(path)) + '.out'
	return {
		ric: ric
		path: path
		out_path: out_path
		is_err_test: path.ends_with('_err.ri')
		expected: os.read_file(out_path) or { '' }
	}
}

struct TestCase {
	ric Ric
mut:
	path        string [required]
	out_path    string [required]
	is_err_test bool   [required]
	ok          bool

	exit_code int
	expected  string [required]
	output    string
}

fn (mut t TestCase) run() {
	result := if t.is_err_test {
		t.ric.execute(.compile, t.path)
	} else {
		t.ric.execute(.run, t.path)
	}
	t.output = result.output
	t.exit_code = result.exit_code
	$if fix ? {
		if t.output != t.expected {
			os.write_file(t.out_path, t.output) or { panic(err) }
		}
		t.ok = true
	} $else {
		t.ok = t.output == t.expected
			&& (if t.is_err_test { t.exit_code != 0 } else { t.exit_code == 0 })
	}
}

fn (t TestCase) result() string {
	file := os.join_path(os.base(os.dir(t.path)), os.base(t.path))
	if t.ok {
		return '${term.ok_message('[ OK ]')} $file'
	}
	indent := ' '.repeat(2)
	format_output := fn (text string) string {
		indent := ' '.repeat(4)
		return if text.len == 0 {
			'${indent}__EMPTY__'
		} else {
			text.split_into_lines().map('$indent$it').join('\n')
		}
	}
	return [
		'${term.fail_message('[FAIL]')} $file',
		'${indent}exit_code: $t.exit_code',
		'${indent}output:',
		format_output(t.output),
		'${indent}expected:',
		format_output(t.expected),
	].map(it + '\n').join('')
}

fn run(paths []string) bool {
	dir := os.real_path(@VMODROOT)
	ric_dir := os.join_path(dir, 'cmd/ric')
	sources := get_sources(paths)

	ric := Ric{
		source: ric_dir
		bin: os.join_path(ric_dir, 'ric')
	}

	assert ric.compile().exit_code == 0

	mut ok := true
	for path in sources {
		mut t := ric.new_test_case(path)
		t.run()
		ok = ok && t.ok
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
