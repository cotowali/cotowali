// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import lsp

fn (mut q Kuqi) did_open(id int, params lsp.DidOpenTextDocumentParams) {
	q.log_message('did open: { id: $id, uri: $params.text_document.uri }', .log)
}

fn (mut q Kuqi) did_change(id int, params lsp.DidChangeTextDocumentParams) {
	q.log_message('did change: { id: $id, uri: $params.text_document.uri }', .log)
}

fn (mut q Kuqi) did_close(id int, params lsp.DidCloseTextDocumentParams) {
	q.log_message('did close: { id: $id, uri: $params.text_document.uri }', .log)
}

fn (mut q Kuqi) did_save(id int, params lsp.DidSaveTextDocumentParams) {
	q.log_message('did save: { id: $id, uri: $params.text_document.uri }', .log)
}
