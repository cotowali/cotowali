module lsp

// method: ‘textDocument/documentColor’
// response: []ColorInformation
pub struct DocumentColorParams {
	text_document TextDocumentIdentifier [json: textDocument]
}

pub struct ColorInformation {
	range Range
	color Color
}

pub struct Color {
	red   int
	green int
	blue  int
	alpha int
}
