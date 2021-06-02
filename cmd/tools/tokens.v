module tools

import cli { Command }
import strings
import cotowari.config { new_config }
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
	config := new_config()
	for path in paths {
		sb.writeln(path)
		s := source.read_file(path) or {
			sb.writeln('    ERROR')
			continue
		}
		for token in new_lexer(s, config) {
			sb.writeln('    $token.short_str()')
		}
	}
	sb.writeln(']')
	println(sb.str())
}
