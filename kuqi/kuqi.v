// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import json
import jsonrpc

interface SendReceiver {
	send(string)
	receive() ?string
}

pub struct Kuqi {
mut:
	io SendReceiver
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

fn (qi &Kuqi) receive() ?string {
	return qi.io.receive()
}

fn (mut qi Kuqi) dispatch(payload string) {
	request := json.decode(jsonrpc.Request, payload) or {
		qi.send(new_error(jsonrpc.parse_error))
		return
	}
	qi.send(new_error(jsonrpc.method_not_found))
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
