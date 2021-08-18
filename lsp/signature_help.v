module lsp

pub struct SignatureHelpOptions {
	trigger_characters   []string [json: triggerCharacters]
	retrigger_characters []string [json: retriggerCharacters]
}

pub enum SignatureHelpTriggerKind {
	invoked = 1
	trigger_character = 2
	content_change = 3
}

// method: ‘textDocument/signatureHelp’
// response: SignatureHelp | none
pub struct SignatureHelpParams {
pub:
	// TODO: utilize struct embedding feature
	// for all structs that use TextDocumentPositionParams
	// embed: TextDocumentPositionParams
	text_document TextDocumentIdentifier [json: textDocument]
	position      Position
	context       SignatureHelpContext
}

pub struct SignatureHelpContext {
pub:
	trigger_kind          SignatureHelpTriggerKind [json: triggerKind]
	trigger_character     string                   [json: triggerCharacter]
	is_retrigger          bool                     [json: isRetrigger]
	active_signature_help SignatureHelp            [json: activeSignatureHelp]
}

pub struct SignatureHelp {
pub:
	signatures []SignatureInformation
pub mut:
	active_parameter int [json: activeParameter]
}

pub struct SignatureInformation {
pub mut:
	label      string
	document   string                 [raw]
	parameters []ParameterInformation
}

pub struct ParameterInformation {
	label string
}

pub struct SignatureHelpRegistrationOptions {
	document_selector  []DocumentFilter [json: documentSelector]
	trigger_characters []string         [json: triggerCharacters]
}
