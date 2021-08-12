// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
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
	shellcheck
	compile
	noemit
	run
}

fn (lic Lic) compile() ? {
	res := os.execute('v -g $lic.source -o $lic.bin')
	if res.exit_code != 0 {
		return error_with_code(res.output, res.exit_code)
	}
	return
}

fn (lic Lic) execute(c LicCommand, file string) os.Result {
	return match c {
		.shellcheck { os.execute('$lic.bin $file | shellcheck -') }
		.compile { os.execute('$lic.bin $file') }
		.noemit { os.execute('$lic.bin --no-emit $file') }
		.run { os.execute('$lic.bin run $file') }
	}
}

fn (lic Lic) new_test_case(path string, opt TestOption) TestCase {
	out := out_path(path)
	return TestCase{
		lic: lic
		opt: opt
		path: path
		out_path: out
		is_err_test: is_err_test_file(path)
		is_todo_test: is_todo_test_file(path)
		is_noemit_test: is_noemit_test_file(path)
		expected: os.read_file(out) or { '' }
	}
}

struct TestOption {
	shellcheck bool
	fix_mode   bool
}

enum TestResultStatus {
	ok
	failed
	fixed
	todo
}

struct TestResult {
	path      string
	exit_code int
	expected  string
	output    string
	elapsed   time.Duration
mut:
	status TestResultStatus
}

struct TestCase {
	lic Lic
	opt TestOption
mut:
	path               string [required]
	out_path           string [required]
	is_shellcheck_test bool
	is_err_test        bool   [required]
	is_todo_test       bool   [required]
	is_noemit_test     bool   [required]
	expected           string [required]
}

fn (t TestCase) is_normal_test() bool {
	return !(t.is_todo_test || t.is_err_test || t.is_noemit_test)
}

fn fix_todo(f string, s FileSuffix) {
	base := f.trim_suffix(suffix(s)).trim_suffix(suffix(.todo))
	os.mv(f, base + suffix(s)) or { panic(err) }
}

fn (t &TestCase) run() TestResult {
	mut sw := time.new_stopwatch()
	sw.start()
	cmd_res := if t.is_shellcheck_test {
		t.lic.execute(.shellcheck, t.path)
	} else if t.is_err_test {
		t.lic.execute(.compile, t.path)
	} else if t.is_noemit_test {
		t.lic.execute(.noemit, t.path)
	} else {
		t.lic.execute(.run, t.path)
	}
	sw.stop()
	mut result := TestResult{
		path: t.path
		elapsed: sw.elapsed()
		expected: t.expected
		output: cmd_res.output
		exit_code: cmd_res.exit_code
	}

	correct_exit_code := if t.is_err_test { result.exit_code != 0 } else { result.exit_code == 0 }
	if t.is_todo_test {
		result.status = .todo
	} else {
		result.status = if result.output == result.expected && correct_exit_code {
			TestResultStatus.ok
		} else {
			TestResultStatus.failed
		}
	}

	if t.opt.fix_mode && !t.is_shellcheck_test {
		if correct_exit_code {
			if t.is_todo_test {
				if result.output == result.expected {
					fix_todo(t.path, .li)
					fix_todo(t.out_path, .out)
					result.status = .fixed
				}
			} else if result.output != result.expected {
				os.write_file(t.out_path, result.output) or { panic(err) }
				result.status = .fixed
			}
		}
	}

	return result
}

fn (result TestResult) summary_message(file string) string {
	status := match result.status {
		.ok, .fixed { term.ok_message('[ OK ]') }
		.todo { term.warn_message('[TODO]') }
		.failed { term.fail_message('[FAIL]') }
	}
	elapsed_ms := f64(result.elapsed.microseconds()) / 1000.0
	msg := '$status ${elapsed_ms:6.2f} ms $file'
	return if result.status == .fixed { '$msg (FIXED)' } else { msg }
}

fn (r TestResult) failed_message(file string) string {
	format_output := fn (text string) string {
		indent := ' '.repeat(4)
		return if text.len == 0 { '${indent}__EMPTY__' } else { indent_each_lines(1, text) }
	}

	mut lines := [
		r.summary_message(file),
		'${indent(1)}exit_code: $r.exit_code',
		'${indent(1)}output:',
		format_output(r.output),
		'${indent(1)}expected:',
		format_output(r.expected),
	]
	if diff_cmd := find_working_diff_command() {
		diff := color_compare_strings(diff_cmd, rand.ulid(), r.expected, r.output)
		lines << [
			'${indent}diff:',
			indent_each_lines(2, diff),
		]
	}

	return lines.map(it + '\n').join('')
}

fn (r TestResult) message() string {
	file := os.real_path(r.path).trim_prefix(os.real_path(@VMODROOT)).trim_prefix('/')
	return match r.status {
		.failed { r.failed_message(file) }
		else { r.summary_message(file) }
	}
}

struct TestSuite {
mut:
	cases []TestCase
}

fn new_test_suite(paths []string, opt TestOption) TestSuite {
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
		exit(1)
	}

	mut cases := []TestCase{}
	for s in sources {
		test := lic.new_test_case(s, opt)
		cases << test
		if opt.shellcheck && test.is_normal_test() {
			cases << TestCase{
				...test
				is_shellcheck_test: true
			}
		}
	}
	return TestSuite{
		cases: cases
	}
}

fn (t TestSuite) run() bool {
	mut sw := time.new_stopwatch()
	sw.start()
	mut threads := []thread TestResultStatus{}
	for tt in t.cases {
		threads << go fn (t TestCase) TestResultStatus {
			res := t.run()
			println(res.message())
			return res.status
		}(tt)
	}
	status_list := threads.wait()
	sw.stop()

	mut ok_n, mut fixed_n, mut todo_n, mut failed_n := 0, 0, 0, 0
	for s in status_list {
		match s {
			.ok { ok_n++ }
			.fixed { fixed_n++ }
			.todo { todo_n++ }
			.failed { failed_n++ }
		}
	}

	println('Total: $t.cases.len, Runtime: ${sw.elapsed().milliseconds()}ms')
	println(term.ok_message('$ok_n Passed'))
	if fixed_n > 0 {
		println(term.ok_message('$fixed_n Fixed'))
	}
	if todo_n > 0 {
		println(term.warn_message('$todo_n Skipped'))
	}
	if failed_n > 0 {
		println(term.fail_message('$failed_n Failed'))
	}

	return failed_n == 0
}

fn main() {
	if ['--help', '-h', 'help'].any(it in os.args) {
		println('Usage: v run tests/run.v [test.li|tests]...')
		return
	}

	shellcheck := '--shellcheck' in os.args
	fix_mode := '--fix' in os.args
	args := os.args.filter(!it.starts_with('-'))
	paths := if args.len > 1 {
		os.args[1..]
	} else {
		['examples', 'tests'].map(os.join_path(@VMODROOT, it))
	}

	t := new_test_suite(paths, shellcheck: shellcheck, fix_mode: fix_mode)
	exit(if t.run() { 0 } else { 1 })
}
