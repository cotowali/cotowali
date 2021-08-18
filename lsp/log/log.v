module log

import os
import time
import json
import strings

pub interface Logger {
	close()
	flush()
	enable()
	disable()
	request(msg string, kind TransportKind)
	response(msg string, kind TransportKind)
	notification(msg string, kind TransportKind)
	set_logpath(path string)
}

pub enum Format {
	json
	text
}

pub struct Log {
mut:
	file           os.File
	format         Format = .json
	buffer         strings.Builder
	file_opened    bool
	enabled        bool
	last_timestamp time.Time = time.now()
pub mut:
	file_path    string
	cur_requests map[int]string
}

pub enum TransportKind {
	send
	receive
}

struct Payload {
	id     int
	method string
	result string [raw]
	params string [raw]
}

enum LogKind {
	send_notification
	recv_notification
	send_request
	recv_request
	send_response
	recv_response
}

pub fn (lk LogKind) str() string {
	return match lk {
		.send_notification { 'send-notification' }
		.recv_notification { 'recv-notification' }
		.send_request { 'send-request' }
		.recv_request { 'recv-request' }
		.send_response { 'send-response' }
		.recv_response { 'recv-response' }
	}
}

pub struct LogItem {
	kind      LogKind
	message   string
	method    string
	timestamp time.Time // unix timestamp
}

pub fn new(format Format) &Log {
	return &Log{
		format: format
		file_opened: false
		enabled: true
		buffer: strings.new_builder(20)
	}
}

// set_logpath sets the filepath of the log file and opens the file.
pub fn (mut l Log) set_logpath(path string) {
	if l.file_opened {
		l.close()
	}

	file := os.open_append(os.real_path(path)) or { panic(err) }

	l.file = file
	l.file_path = path
	l.file_opened = true
	l.enabled = true
}

// flush flushes the contents of the log file into the disk.
pub fn (mut l Log) flush() {
	l.file.flush()
}

// close closes the log file.
pub fn (mut l Log) close() {
	if !l.file_opened {
		return
	}

	l.file_opened = false
	l.file.close()
}

// enable enables/starts the logging.
pub fn (mut l Log) enable() {
	l.enabled = true
}

// disable disables/stops the logging.
pub fn (mut l Log) disable() {
	l.enabled = false
}

// write writes the log item into the log file or in the
// buffer if the file is not opened yet.
[manualfree]
fn (mut l Log) write(item LogItem) {
	if !l.enabled {
		return
	}

	content := item.encode(l.format, l.last_timestamp)
	if l.file_opened {
		if l.buffer.len != 0 {
			unsafe {
				l.file.write_ptr(l.buffer.data, l.buffer.len)
				l.buffer.free()
			}
		}

		l.file.writeln(content) or { panic(err) }
	} else {
		l.buffer.writeln(content)
	}

	l.last_timestamp = item.timestamp
	unsafe { content.free() }
}

// request logs a request message.
pub fn (mut l Log) request(msg string, kind TransportKind) {
	req_kind := match kind {
		.send { LogKind.send_request }
		.receive { LogKind.recv_request }
	}

	mut req_method := ''
	if kind == .receive {
		payload := json.decode(Payload, msg) or { Payload{} }
		l.cur_requests[payload.id] = payload.method
		req_method = payload.method
	}

	l.write(kind: req_kind, message: msg, method: req_method, timestamp: time.now())
}

// response logs a response message.
pub fn (mut l Log) response(msg string, kind TransportKind) {
	resp_kind := match kind {
		.send { LogKind.send_response }
		.receive { LogKind.recv_response }
	}

	payload := json.decode(Payload, msg) or { Payload{} }
	mut resp_method := ''
	if payload.id in l.cur_requests {
		resp_method = l.cur_requests[payload.id]
		l.cur_requests.delete(payload.id)
	}

	l.write(kind: resp_kind, message: msg, method: resp_method, timestamp: time.now())
}

// notification logs a notification message.
pub fn (mut l Log) notification(msg string, kind TransportKind) {
	notif_kind := match kind {
		.send { LogKind.send_notification }
		.receive { LogKind.recv_notification }
	}

	l.write(kind: notif_kind, message: msg, timestamp: time.now())
}

// encode returns the string representation of the format
// based on the given format
fn (li LogItem) encode(format Format, last_timestamp time.Time) string {
	match format {
		.json { return li.json() }
		.text { return li.text(last_timestamp) }
	}
}

// json is a JSON string representation of the log item.
pub fn (li LogItem) json() string {
	return '{"kind":"$li.kind","message":$li.message,"timestamp":$li.timestamp.unix}'
}

// text is the standard LSP text log representation of the log item.
// TODO: ignore this for now
pub fn (li LogItem) text(last_timestamp time.Time) string {
	payload := json.decode(Payload, li.message) or { Payload{} }
	elapsed := li.timestamp - last_timestamp
	elapsed_ms := elapsed.milliseconds()

	method := if li.method.len != 0 { li.method } else { payload.method }
	message := match li.kind {
		.send_notification { 'Sending notification \'$method\'.' }
		.recv_notification { 'Received notification \'$method\'.' }
		.send_request { 'Sending request \'$method - ($payload.id)\'.' }
		.recv_request { 'Received request \'$method - ($payload.id)\'.' }
		.send_response { 'Sending response \'$method - ($payload.id)\' took ${elapsed_ms}ms' }
		.recv_response { 'Received response \'$method - ($payload.id)\' in ${elapsed_ms}ms' }
	}

	params_msg := if li.message == 'null' {
		'No result returned.'
	} else if li.kind == .send_response || li.kind == .recv_response {
		'Result: ' + li.message
	} else {
		'Params: ' + li.message
	}
	return '[Trace - $li.timestamp.hhmmss()] $message\n$params_msg\n\n'
}
