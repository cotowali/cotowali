module lsp

// method: ‘client/registerCapability’
// response: void
pub struct RegistrationParams {
	registrations []Registration
}

pub struct Registration {
	id               int
	method           string
	register_options string [raw]
}

// base interface for registration register_options
// pub struct TextDocumentRegistrationOptions {
// document_selector []DocumentFilter [json:documentSelector]
// }
// method: ‘client/unregisterCapability’
// response: void
pub struct UnregistrationParams {
	unregistrations []Unregistration
}

pub struct Unregistration {
	id     int
	method string
}
