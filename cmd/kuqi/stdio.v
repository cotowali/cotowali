// https://github.com/vlang/vls/blob/61f3cd584b51154d5ae6148d78e1828bef7252f8/cmd/vls/stdio.v
module main

import strings

const (
	content_length = 'Content-Length: '
)

fn C.fgetc(stream &C.FILE) int

struct Stdio {
}

pub fn (_ Stdio) send(output string) {
	print('$content_length$output.len\r\n\r\n$output')
}

[manualfree]
pub fn (_ Stdio) receive() ?string {
	first_line := get_raw_input()
	if first_line.len < 1 || !first_line.starts_with(content_length) {
		return error('content length is missing')
	}
	mut conlen := first_line[content_length.len..].int()
	mut buf := strings.new_builder(conlen)
	for conlen >= 0 {
		c := C.fgetc(&C.FILE(C.stdin))
		$if !windows {
			if c == 10 {
				continue
			}
		}
		buf.write_byte(u8(c))
		conlen--
	}
	payload := buf.str()
	unsafe { buf.free() }
	return payload[1..]
}

fn get_raw_input() string {
	eof := C.EOF
	mut buf := strings.new_builder(200)
	for {
		c := C.fgetc(&C.FILE(C.stdin))
		chr := u8(c)
		if buf.len > 2 && (c == eof || chr in [`\r`, `\n`]) {
			break
		}
		buf.write_byte(chr)
	}
	return buf.str()
}
