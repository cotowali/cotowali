module lsp

// method: ‘textDocument/formatting’
// response: []TextEdit | none
pub struct DocumentFormattingParams {
pub:
	text_document TextDocumentIdentifier [json: textDocument]
	options       FormattingOptions
}

pub struct FormattingOptions {
	tab_size      int  [json: tabSize]
	insert_spaces bool [json: insertSpaces]
	// [key] bool | number | string
}

// method: ‘textDocument/rangeFormatting’
// response: []TextEdit | none
pub struct DocumentRangeFormattingParams {
	text_document TextDocumentIdentifier [json: textDocument]
	range         Range
	options       FormattingOptions
}

pub struct DocumentOnTypeFormattingOptions {
	first_trigger_character string   [json: firstTriggerCharacter]
	more_trigger_character  []string [json: moreTriggerCharacter]
}

// method: ‘textDocument/onTypeFormatting’
// response: []TextEdit | none
pub struct DocumentOnTypeFormattingParams {
	text_document TextDocumentIdentifier [json: textDocument]
	position      Position
	ch            string
	options       FormattingOptions
}

pub struct DocumentOnTypeFormattingRegistrationOptions {
	document_selector       []DocumentFilter [json: documentSelector]
	first_trigger_character string           [json: firstTriggerCharacter]
	more_trigger_character  []string         [json: moreTriggerCharacter]
}
