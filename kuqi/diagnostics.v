// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import lsp
import jsonrpc
import cotowali.errors { Warn }

[manualfree]
fn (mut q Kuqi) show_diagnostics(uri lsp.DocumentUri) {
	path := uri.path()
	errors := q.ctx.errors.all().filter(it.source().path == path)

	mut diagnostics := []lsp.Diagnostic{cap: errors.len}

	for e in errors {
		diagnostics << lsp.Diagnostic{
			range: pos_to_range(e.pos)
			severity: if e is Warn { lsp.severity(.warning) } else { lsp.severity(.error) }
			message: e.msg
		}
	}

	q.send(jsonrpc.NotificationMessage<lsp.PublishDiagnosticsParams>{
		method: lsp.method_publish_diagnostics
		params: lsp.PublishDiagnosticsParams{
			uri: uri
			diagnostics: diagnostics
		}
	})
	unsafe { diagnostics.free() }
}
