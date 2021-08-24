// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import lsp
import cotowali.source { new_source }

fn (mut q Kuqi) did_open(id int, params lsp.DidOpenTextDocumentParams) {
	q.log_message('did open: { id: $id, uri: $params.text_document.uri }', .log)
	q.show_diagnostics(params.text_document.uri)
	document := params.text_document
	path := document.uri.path()
	if path !in q.ctx.sources {
		q.ctx.sources[path] = new_source(path, document.text)
	}
}

fn (mut q Kuqi) did_change(id int, params lsp.DidChangeTextDocumentParams) {
	q.log_message('did change: { id: $id, uri: $params.text_document.uri }', .log)

	path := params.text_document.uri.path()
	text := params.content_changes[0].text
	q.ctx.sources[path] = new_source(path, text)
}

fn (mut q Kuqi) did_close(id int, params lsp.DidCloseTextDocumentParams) {
	q.log_message('did close: { id: $id, uri: $params.text_document.uri }', .log)

	path := params.text_document.uri.path()
	q.ctx.sources.delete(path)
}

fn (mut q Kuqi) did_save(id int, params lsp.DidSaveTextDocumentParams) {
	q.log_message('did save: { id: $id, uri: $params.text_document.uri }', .log)
}
