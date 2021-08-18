module lsp

pub struct RenameOptions {
	prepare_provider bool [json: prepareProvider]
}

// method: ‘textDocument/rename’
// response: WorkspaceEdit | none
pub struct RenameParams {
	text_docuent TextDocumentIdentifier [json: textDocument]
	position     Position
	new_name     string                 [json: newName]
}

pub struct RenameRegistrationOptions {
	document_selector []DocumentFilter [json: documentSelector]
	prepare_provider  bool             [json: prepareProvider]
}

// method: ‘textDocument/prepareRename’
// response: Range | { range: Range, placeholder: string } | none
// request: TextDocumentPositionParams
