module tools

import cli { Command }
import strings
import cotowari.lexer { new_lexer }
import cotowari.source

const (
	tokens_command = Command{
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
		for token in new_lexer(s) {
			text := token.text.replace_each(['\r', r'\r', '\n', r'\n'])
			sb.writeln('    .$token.kind $text')
		}
	}
	sb.writeln(']')
	println(sb)
}
