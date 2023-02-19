// Copyright (c) 2021-2023 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import json
import jsonrpc
import lsp
import cotowali.context { Context }

// for libgc.a
#flag -lpthread

interface SendReceiver {
	send(string)
	receive() ?string
}

pub struct Kuqi {
mut:
	io     SendReceiver
	status ServerStatus = .off
	ctx    &Context
}

pub enum ServerStatus {
	off
	initialized
	shutdowned
}

pub fn new(io SendReceiver) Kuqi {
	return Kuqi{
		io: io
		ctx: new_context()
	}
}

fn (mut qi Kuqi) send[T](data T) {
	encoded := json.encode(data)
	qi.io.send(encoded)
}

fn (mut qi Kuqi) send_null(id int) {
	qi.io.send('{ "jsonrpc": "2.0", "id": ${id}, "result": null }')
}

fn (mut q Kuqi) decode[T](data string) ?T {
	decoded := json.decode(T, data) or {
		q.io.send(json.encode(new_error(jsonrpc.invalid_request)))
		return none
	}
	return decoded
}

fn (qi &Kuqi) receive() ?string {
	return qi.io.receive()
}

fn (mut q Kuqi) dispatch(payload string) ? {
	request := json.decode(jsonrpc.Request, payload) or {
		q.send(new_error(jsonrpc.parse_error))
		return
	}

	id, params := request.id, request.params
	if q.status != .initialized {
		match request.method {
			'initialize' {
				q.initialize(id, q.decode[lsp.InitializeParams](params)?)
			}
			'exit' {
				exit(if q.status == .shutdowned { 0 } else { 1 })
			}
			else {
				q.send(new_error(if q.status == .shutdowned {
					jsonrpc.invalid_request
				} else {
					jsonrpc.server_not_initialized
				}))
			}
		}
		return
	}

	match request.method {
		'initialized' { q.log_message('initialized Kuqi', .log) }
		'shutdown' { q.shutdown(id) }
		lsp.method_did_open { q.did_open(id, q.decode[lsp.DidOpenTextDocumentParams](params)?) }
		lsp.method_did_change { q.did_change(id, q.decode[lsp.DidChangeTextDocumentParams](params)?) }
		lsp.method_did_close { q.did_close(id, q.decode[lsp.DidCloseTextDocumentParams](params)?) }
		lsp.method_did_save { q.did_save(id, q.decode[lsp.DidSaveTextDocumentParams](params)?) }
		else {}
	}
}

pub fn (mut qi Kuqi) serve() {
	for {
		payload := qi.receive() or { continue }
		qi.dispatch(payload) or { continue }
	}
}

fn new_error(code int) jsonrpc.ResponseWithError[string] {
	return jsonrpc.ResponseWithError[string]{
		error: jsonrpc.new_response_error(code)
	}
}

fn (mut qi Kuqi) initialize(id int, params lsp.InitializeParams) {
	qi.show_message('Welcome to Kuqi', .info)
	res := jsonrpc.Response[lsp.InitializeResult]{
		id: id
		result: lsp.InitializeResult{
			capabilities: lsp.ServerCapabilities{
				text_document_sync: 1
			}
		}
	}
	qi.status = .initialized
	qi.send(res)
}

fn (mut q Kuqi) shutdown(id int) {
	q.status = .shutdowned
	q.log_message('shutdowned Kuqi', .log)
	q.send_null(id)
}
