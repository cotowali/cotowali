module lsp

pub struct CodeActionOptions {
	code_action_kinds []string [json: codeActionKinds]
}

// method: ‘textDocument/codeAction’
// response [](Command | CodeAction) | null
pub struct CodeActionParams {
	text_document TextDocumentIdentifier [json: textDocument]
	range         Range
	context       CodeActionContext
}

// type CodeActionKind string
pub const (
	empty                   = ''
	quick_fix               = 'quickfix'
	refactor                = 'refactor'
	refactor_extract        = 'refactor.extract'
	refactor_inline         = 'refactor.inline'
	refactor_rewrite        = 'refactor.rewrite'
	source                  = 'source'
	source_organize_imports = 'source.organizeImports'
)

pub struct CodeActionContext {
	diagnostics []Diagnostic
	only        []string
}

pub struct CodeAction {
	title string
	kind  string
	// CodeActionKind
	diagnostics []Diagnostic
	edit        WorkspaceEdit
	command     Command
}

pub struct CodeActionRegistrationOptions {
	document_selector []DocumentFilter [json: documentSelector]
	code_action_kinds []string         [json: codeActionKinds]
}
