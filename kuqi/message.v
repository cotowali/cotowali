// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import lsp
import jsonrpc

fn (mut q Kuqi) log_message(message string, typ lsp.MessageType) {
	q.send(jsonrpc.NotificationMessage<lsp.LogMessageParams>{
		method: lsp.method_log_message
		params: lsp.LogMessageParams{
			@type: typ
			message: message
		}
	})
}

fn (mut q Kuqi) show_message(message string, typ lsp.MessageType) {
	q.send(jsonrpc.NotificationMessage<lsp.ShowMessageParams>{
		method: lsp.method_show_message
		params: lsp.ShowMessageParams{
			@type: typ
			message: message
		}
	})
}

fn (mut q Kuqi) show_message_request(message string, actions []lsp.MessageActionItem, typ lsp.MessageType) {
	q.send(jsonrpc.NotificationMessage<lsp.ShowMessageRequestParams>{
		method: lsp.method_show_message_request
		params: lsp.ShowMessageRequestParams{
			@type: typ
			message: message
			actions: actions
		}
	})
}
