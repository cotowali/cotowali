module lsp

// method: ‘window/showMessage’
// notification
pub struct ShowMessageParams {
	@type MessageType
	// @type int
	message string
}

pub enum MessageType {
	error = 1
	warning = 2
	info = 3
	log = 4
}

// method: ‘window/showMessageRequest’
// response: MessageActionItem | none / null
pub struct ShowMessageRequestParams {
	@type   MessageType
	message string
	actions []MessageActionItem
}

pub struct MessageActionItem {
	title string
}

// method: ‘window/logMessage’
// notification
pub struct LogMessageParams {
	@type   MessageType
	message string
}

// method: ‘telemetry/event
// notification
// any
