module tracer

pub struct Tracer {
mut:
	indent  int
	newline bool = true
}

pub fn new_tracer() Tracer {
	return {}
}

[inline]
pub fn (t Tracer) write_indent() {
	eprint('  '.repeat(t.indent))
}

pub fn (mut t Tracer) write(msg string) {
	if t.newline {
		t.write_indent()
	}
	eprint(msg)
	if msg.len > 0 && msg[msg.len - 1] == `\n` {
		t.newline = true
	}
}

[inline]
pub fn (mut t Tracer) writeln(msg string) {
	if t.newline {
		t.write_indent()
	}
	eprintln(msg)
	t.newline = true
}

pub fn (mut t Tracer) begin_fn(name string, args ...string) {
	t.writeln('${name}(${args.join(', ')})')
	t.indent++
}

pub fn (mut t Tracer) end_fn() {
	t.indent--
}

pub fn (mut t Tracer) write_fields(fields map[string]string) {
	for k, v in fields {
		t.write_field(k, v)
	}
}

pub fn (mut t Tracer) write_field(name string, v string) {
	t.writeln('$name: $v')
}

pub fn (mut t Tracer) write_object(name string, fields map[string]string) {
	t.begin_object(name)
	t.write_fields(fields)
	t.end_object()
}

pub fn (mut t Tracer) begin_object(name string) {
	t.writeln('$name {')
	t.indent++
}

pub fn (mut t Tracer) end_object() {
	t.indent--
	t.writeln('}')
}
