// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import lsp
import cotowali.source { Source, new_source }
import cotowali.parser
import cotowali.ast
import cotowali.checker
import os

fn (mut q Kuqi) did_open(id int, params lsp.DidOpenTextDocumentParams) {
	q.log_message('did open: { id: ${id}, uri: ${params.text_document.uri} }', .log)
	q.show_diagnostics(params.text_document.uri)
	document := params.text_document
	path := document.uri.path()
	if path !in q.ctx.sources {
		q.process_source(new_source(path, document.text))
	}
}

fn (mut q Kuqi) did_change(id int, params lsp.DidChangeTextDocumentParams) {
	q.log_message('did change: { id: ${id}, uri: ${params.text_document.uri} }', .log)

	path := params.text_document.uri.path()
	text := params.content_changes[0].text // content_changes have just one item that have entire of source text
	q.process_source(new_source(path, text))
}

fn (mut q Kuqi) did_close(id int, params lsp.DidCloseTextDocumentParams) {
	q.log_message('did close: { id: ${id}, uri: ${params.text_document.uri} }', .log)

	path := params.text_document.uri.path()
	q.ctx.sources.delete(path)
}

fn (mut q Kuqi) did_save(id int, params lsp.DidSaveTextDocumentParams) {
	q.log_message('did save: { id: ${id}, uri: ${params.text_document.uri} }', .log)
}

fn (mut q Kuqi) process_source(s &Source) {
	is_builtin := s.path == os.join_path(os.real_path(@VMODROOT), 'std/builtin.li')
	mut ctx := new_context(no_builtin: is_builtin)
	q.ctx = ctx

	mut f := parser.parse(s, ctx)
	if !ctx.errors.has_syntax_error() {
		ast.resolve(mut f, ctx)
		checker.check(mut f, ctx)
	}
	q.show_diagnostics(lsp.document_uri_from_path(s.path))
}
