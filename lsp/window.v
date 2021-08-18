module lsp

pub const (
	method_show_message         = 'window/showMessage'
	method_log_message          = 'window/logMessage'
	method_show_message_request = 'window/showMessageRequest'
)

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
