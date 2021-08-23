module lsp

pub struct Position {
pub:
	line      int
	character int
}

pub struct Range {
pub:
	start Position
	end   Position
}

pub struct TextEdit {
	range    Range
	new_text string [json: newText]
}

pub struct TextDocumentIdentifier {
pub:
	uri DocumentUri
}

pub struct TextDocumentEdit {
	text_document VersionedTextDocumentIdentifier [json: textDocument]
	edits         []TextEdit
}

pub struct TextDocumentItem {
pub:
	uri         DocumentUri
	language_id string      [json: languageId]
	version     int
	text        string
}

pub struct VersionedTextDocumentIdentifier {
pub:
	uri     DocumentUri
	version int
}

pub struct Location {
pub mut:
	uri   DocumentUri
	range Range
}

pub struct LocationLink {
pub:
	origin_selection_range Range       [json: originSelectionRange]
	target_uri             DocumentUri [json: targetUri]
	target_range           Range       [json: targetRange]
	target_selection_range Range       [json: targetSelectionRange]
}

// pub struct TextDocumentContentChangeEvent {
// range Range
// text string
// }
pub struct TextDocumentPositionParams {
pub:
	text_document TextDocumentIdentifier [json: textDocument]
	position      Position
}

pub const (
	markup_kind_plaintext = 'plaintext'
	markup_kind_markdown  = 'markdown'
)

pub struct MarkupContent {
	kind string
	// MarkupKind
	value string
}

pub struct TextDocument {
	uri         DocumentUri
	language_id string
	version     int
	line_count  int
}

pub struct FullTextDocument {
	uri          DocumentUri
	language_id  string
	version      int
	content      string
	line_offsets []int
}
