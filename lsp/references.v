module lsp

// method: ‘textDocument/references’
// response: []Location | none
pub struct ReferenceParams {
	// extend: TextDocumentPositionParams
	context ReferenceContext
}

pub struct ReferenceContext {
	include_declaration bool
}
