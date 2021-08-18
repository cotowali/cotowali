// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import json
import jsonrpc
import lsp

interface SendReceiver {
	send(string)
	receive() ?string
}

pub struct Kuqi {
mut:
	io     SendReceiver
	status ServerStatus = .off
}

pub enum ServerStatus {
	off
	initialized
	shutdowned
}

pub fn new(io SendReceiver) Kuqi {
	return Kuqi{
		io: io
	}
}

fn (mut qi Kuqi) send<T>(data T) {
	encoded := json.encode(data)
	qi.io.send(encoded)
}

fn (mut qi Kuqi) send_null(id int) {
	qi.io.send('{ "jsonrpc": "2.0", "id": $id, "result": null }')
}

fn (qi &Kuqi) receive() ?string {
	return qi.io.receive()
}

fn (mut q Kuqi) dispatch(payload string) {
	request := json.decode(jsonrpc.Request, payload) or {
		q.send(new_error(jsonrpc.parse_error))
		return
	}

	if q.status == .initialized {
		match request.method {
			'initialized' { q.log_message('initialized Kuqi', .log) }
			else {}
		}
	} else {
		match request.method {
			'initialize' {
				params := json.decode(lsp.InitializeParams, request.params) or {
					q.send(new_error(jsonrpc.invalid_request))
					return
				}
				q.initialize(request.id, params)
			}
			'exit' {
				// TODO
			}
			else {
				q.send(new_error(if q.status == .shutdowned {
					jsonrpc.invalid_request
				} else {
					jsonrpc.server_not_initialized
				}))
			}
		}
	}
}

pub fn (mut qi Kuqi) serve() {
	for {
		payload := qi.receive() or { continue }
		qi.dispatch(payload)
	}
}

fn new_error(code int) jsonrpc.ResponseWithError<string> {
	return jsonrpc.ResponseWithError<string>{
		error: jsonrpc.new_response_error(code)
	}
}

fn (mut qi Kuqi) initialize(id int, params lsp.InitializeParams) {
	qi.show_message('Welcome to Kuqi', .info)
	res := jsonrpc.Response<lsp.InitializeResult>{
		id: id
		result: lsp.InitializeResult{
			capabilities: lsp.ServerCapabilities{}
		}
	}
	qi.status = .initialized
	qi.send(res)
}
