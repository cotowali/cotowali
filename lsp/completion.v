module lsp

pub struct CompletionOptions {
pub mut:
	resolve_provider   bool     [json: resolveProvider]
	trigger_characters []string [json: triggerCharacters]
}

pub struct CompletionItemSettings {
	snippet_support           bool     [json: snippetSupport]
	commit_characters_support bool     [json: commitCharactersSupport]
	documentation_format      bool     [json: documentationFormat]
	preselect_support         bool     [json: preselectSupport]
	deprecated_support        bool     [json: deprecatedSupport]
	tag_support               ValueSet [json: tag_support]
}

// method: ‘textDocument/completion’
// response: []CompletionItem | CompletionList | none
pub struct CompletionParams {
pub:
	// extend: TextDocumentPositionParams
	text_document TextDocumentIdentifier [json: textDocument]
	position      Position
	context       CompletionContext
}

pub enum CompletionTriggerKind {
	invoked = 1
	trigger_character = 2
	trigger_for_incomplete_completions = 3
}

pub struct CompletionContext {
pub:
	trigger_kind      CompletionTriggerKind [json: triggerKind]
	trigger_character string                [json: triggerCharacter]
}

pub struct CompletionList {
pub:
	is_incomplete bool             [json: isIncomplete]
	items         []CompletionItem
}

pub enum InsertTextFormat {
	plain_text = 1
	snippet = 2
}

pub struct CompletionItem {
pub mut:
	label string
	kind  CompletionItemKind
	// TODO: comment the unnecessary fields for now to avoid any errors
	// detail        string
	// documentation string | MarkupContent
	// documentation MarkupContent
	// deprecated    bool
	// preselect bool
	// sort_text string [json:sortText]
	// filter_text string [json:filterText]
	insert_text        string           [json: insertText]
	insert_text_format InsertTextFormat [json: insertTextFormat] = .plain_text
	// text_edit TextEdit [json:textEdit]
	// additional_text_edits []TextEdit [json:additionalTextEdits]
	// commit_characters []string [json:commitCharacters]
	// command Command
	// data string [raw]
}

pub enum CompletionItemKind {
	text = 1
	method = 2
	function = 3
	constructor = 4
	field = 5
	variable = 6
	class = 7
	interface_ = 8
	module_ = 9
	property = 10
	unit = 11
	value = 12
	enum_ = 13
	keyword = 14
	snippet = 15
	color = 16
	file = 17
	reference = 18
	folder = 19
	enum_member = 20
	constant = 21
	struct_ = 22
	event = 23
	operator = 24
	type_parameter = 25
}

pub struct CompletionRegistrationOptions {
	document_selector     []DocumentFilter [json: documentSelector]
	trigger_characters    []string         [json: triggerCharacters]
	all_commit_characters []string         [json: allCommitCharacters]
	resolve_provider      bool             [json: resolveProvider]
}

// method: ‘completionItem/resolve’
// response: CompletionItem
// request: CompletionItem
