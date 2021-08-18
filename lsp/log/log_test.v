module log

import json

struct TestLogItem {
	kind    string
	message string
}

fn test_notification_send() {
	mut lg := new(.json)

	lg.notification('"Hello!"', .send)
	buf := lg.buffer.str()
	result := json.decode(TestLogItem, buf) or {
		eprintln(err.msg)
		assert false
		return
	}

	assert result.kind == 'send-notification'
	assert result.message == 'Hello!'
}

fn test_notification_receive() {
	mut lg := new(.json)

	lg.notification('"Received!"', .receive)
	buf := lg.buffer.str()
	result := json.decode(TestLogItem, buf) or {
		eprintln(err.msg)
		assert false
		return
	}

	assert result.kind == 'recv-notification'
	assert result.message == 'Received!'
}

fn test_request_send() {
	mut lg := new(.json)

	lg.request('"Request sent."', .send)
	buf := lg.buffer.str()
	result := json.decode(TestLogItem, buf) or {
		eprintln(err.msg)
		assert false
		return
	}

	assert result.kind == 'send-request'
	assert result.message == 'Request sent.'
}

fn test_request_receive() {
	mut lg := new(.json)

	lg.request('"Request received."', .receive)
	buf := lg.buffer.str()
	result := json.decode(TestLogItem, buf) or {
		eprintln(err.msg)
		assert false
		return
	}

	assert result.kind == 'recv-request'
	assert result.message == 'Request received.'
}

fn test_response_send() {
	mut lg := new(.json)

	lg.response('"Response sent."', .send)
	buf := lg.buffer.str()
	result := json.decode(TestLogItem, buf) or {
		eprintln(err.msg)
		assert false
		return
	}

	assert result.kind == 'send-response'
	assert result.message == 'Response sent.'
}

fn test_response_receive() {
	mut lg := new(.json)

	lg.response('"Response received."', .receive)
	buf := lg.buffer.str()
	result := json.decode(TestLogItem, buf) or {
		eprintln(err.msg)
		assert false
		return
	}

	assert result.kind == 'recv-response'
	assert result.message == 'Response received.'
}

fn test_log_item_text() {
	mut lg := new(.text)

	lg.request('{"jsonrpc":"2.0","id":1,"method":"hello","params":{"name":"Bob"}}', .send)
	lg.request('{"jsonrpc":"2.0","id":1,"method":"hello","params":{"name":"Bob"}}', .receive)
	lg.response('{"jsonrpc":"2.0","id":1,"result":"Hello Bob!"}', .send)
	lg.response('{"jsonrpc":"2.0","id":1,"result":"Hello Bob!"}', .receive)
	lg.notification('{"jsonrpc":"2.0","method":"wave","params":{"name":"Bob"}}', .send)
	lg.notification('{"jsonrpc":"2.0","method":"wave","params":{"name":"Bob"}}', .receive)

	content := lg.buffer.str()
	assert content.len > 0
}
