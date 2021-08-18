module lsp

// method: ‘textDocument/documentSymbol’
// response: []DocumentSymbol | []SymbolInformation | none
pub struct DocumentSymbolParams {
pub:
	text_document TextDocumentIdentifier [json: textDocument]
}

pub enum SymbolKind {
	file = 1
	module_ = 2
	namespace = 3
	package = 4
	class = 5
	method = 6
	property = 7
	field = 8
	constructor = 9
	enum_ = 10
	interface_ = 11
	function = 12
	variable = 13
	constant = 14
	string = 15
	number = 16
	boolean = 17
	array = 18
	object = 19
	key = 20
	null = 21
	enum_member = 22
	struct_ = 23
	event = 24
	operator = 25
	type_parameter = 26
}

pub struct DocumentSymbol {
pub mut:
	name            string
	detail          string
	kind            SymbolKind
	deprecated      bool
	range           Range
	selection_range Range            [json: selectionRange]
	children        []DocumentSymbol
}

pub struct SymbolInformation {
pub mut:
	name           string
	kind           SymbolKind
	deprecated     bool
	location       Location
	container_name string     [json: containerName]
}
