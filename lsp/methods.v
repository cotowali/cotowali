// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module lsp

// text_sync.v
pub const (
	method_did_open   = 'textDocument/didOpen'
	method_did_change = 'textDocument/didChange'
	method_did_close  = 'textDocument/didClose'
	method_did_save   = 'textDocument/didSave'
)

// window.v
pub const (
	method_show_message         = 'window/showMessage'
	method_log_message          = 'window/logMessage'
	method_show_message_request = 'window/showMessageRequest'
)

// diagnostics.v
pub const (
	method_publish_diagnostics = 'textDocument/publishDiagnostics'
)
