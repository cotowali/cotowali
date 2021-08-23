// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module kuqi

import lsp
import jsonrpc

[manualfree]
fn (mut q Kuqi) show_diagnostics(uri lsp.DocumentUri) {
	mut diagnostics := []lsp.Diagnostic{}

	diagnostics << lsp.Diagnostic{
		range: lsp.Range{
			start: lsp.Position{
				line: 0
				character: 0
			}
			end: lsp.Position{
				line: 0
				character: 0
			}
		}
		severity: .error
		message: 'dummy error'
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
