module lsp

// method: ‘textDocument/documentHighlight’
// response: []DocumentHighlight | none
// request: TextDocumentPositionParams
pub struct DocumentHighlight {
	range Range
	kind  int
}

pub enum DocumentHighlightKind {
	text = 1
	read = 2
	write = 3
}
