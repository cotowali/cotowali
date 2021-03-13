module dev

import cli { Command }
import strings
import vash.parser
import vash.lexer
import vash.source

const (
	tokens = Command{
		name: 'tokens'
		description: 'print tokens'
		execute: fn (cmd Command) ? {
			if cmd.args.len == 0 {
				cmd.execute_help()
				return
			}
			print_files_tokens(cmd.args)
			return
		}
	}
	ast    = Command{
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

fn print_files_tokens(paths []string) {
	mut sb := strings.new_builder(100)
	sb.writeln('[')
	for path in paths {
		sb.writeln(path)
		s := source.read_file(path) or {
			sb.writeln('    ERROR')
			continue
		}
		for token in lexer.new(s) {
			text := token.text.replace_each(['\r', r'\r', '\n', r'\n'])
			sb.writeln('    .$token.kind $text')
		}
	}
	sb.writeln(']')
	println(sb)
}

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

pub const (
	command = Command{
		name: 'dev'
		description: 'development tools'
		execute: fn (cmd Command) ? {
			cmd.execute_help()
			return
		}
		commands: [tokens, ast]
	}
)
