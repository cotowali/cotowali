module lsp

pub struct TextDocumentSyncOptions {
	open_close           bool        [json: openClose]
	change               int = int(TextDocumentSyncKind.none_)
	will_save            bool        [json: willSave]
	will_save_wait_until bool        [json: willSaveWaitUntil]
	save                 SaveOptions
}

pub struct SaveOptions {
	include_text bool [json: includeText]
}

// method: ‘textDocument/didOpen’
// notification
pub struct DidOpenTextDocumentParams {
pub:
	text_document TextDocumentItem [json: textDocument]
}

// method: ‘textDocument/didChange’
// notification
pub struct DidChangeTextDocumentParams {
pub:
	text_document   VersionedTextDocumentIdentifier  [json: textDocument]
	content_changes []TextDocumentContentChangeEvent [json: contentChanges]
}

pub struct TextDocumentContentChangeEvent {
pub:
	// range Range
	// range_length int [json:rangeLength]
	text string
}

pub struct TextDocumentChangeRegistrationOptions {
	document_selector []DocumentFilter [json: documentSelector]
	sync_kind         int              [json: syncKind]
}

// method: ‘textDocument/willSave’
// notification
pub struct WillSaveTextDocumentParams {
	text_document TextDocumentIdentifier [json: textDocument]
	reason        int
}

pub enum TextDocumentSaveReason {
	manual = 1
	after_delay = 2
	focusout = 3
}

// ‘textDocument/willSaveWaitUntil’
// response: []TextEdit | null
// request: WillSaveTextDocumentParams
// method: ‘textDocument/didSave’
// notification
pub struct DidSaveTextDocumentParams {
pub:
	text_document TextDocumentIdentifier [json: textDocument]
	text          string
}

// method: ‘textDocument/didClose’
// notification
pub struct DidCloseTextDocumentParams {
pub:
	text_document TextDocumentIdentifier [json: textDocument]
}
