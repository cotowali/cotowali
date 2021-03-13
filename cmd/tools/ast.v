module tools

import cli { Command }
import strings
import vash.parser

const (
	ast_command = Command{
		name: 'ast'
		description: 'print ast'
		execute: fn (cmd Command) ? {
			if cmd.args.len == 0 {
				cmd.execute_help()
				return
			}
			print_files_ast(cmd.args)
			return
		}
	}
)

fn print_files_ast(paths []string) {
	mut sb := strings.new_builder(100)
	sb.writeln('[')
	for path in paths {
		f := parser.parse_file(path) or {
			sb.writeln('    ERROR')
			continue
		}
		for line in f.str().split_into_lines() {
			sb.writeln('    $line')
		}
	}
	sb.writeln(']')
	println(sb)
}
