module lsp

pub struct WorkspaceFolder {
	uri  DocumentUri
	name string
}

pub struct WorkspaceEdit {
	document_changes    bool     [json: documentChanges]
	resource_operations []string [json: resourceOperations]
	failure_handling    string   [json: failureHandling]
}

pub struct DidChangeWorkspaceFoldersParams {
	event WorkspaceFoldersChangeEvent
}

pub struct WorkspaceFoldersChangeEvent {
	added   []WorkspaceFolder
	removed []WorkspaceFolder
}

// method: ‘workspace/didChangeConfiguration’,
// notification
pub struct DidChangeConfigurationParams {
	settings string [raw]
}

// method: ‘workspace/configuration’
// response: []any / []string
pub struct ConfigurationParams {
	items []ConfigurationItem
}

pub struct ConfigurationItem {
	scope_uri DocumentUri [json: scopeUri]
	section   string
}

// method: ‘workspace/didChangeWatchedFiles’
// notification
pub struct DidChangeWatchedFilesParams {
pub:
	changes []FileEvent
}

pub struct FileEvent {
pub:
	uri   DocumentUri
	@type int
}

pub enum FileChangeType {
	created = 1
	changed = 2
	deleted = 3
}

pub struct DidChangeWatchedFilesRegistrationOptions {
	watchers []FileSystemWatcher
}

// The  glob pattern to watch.
// Glob patterns can have the following syntax:
// - `*` to match one or more characters in a path segment
// - `?` to match on one character in a path segment
// - `**` to match any number of path segments, including none
// - `{}` to group conditions (e.g. `**​/*.{ts,js}` matches all TypeScript and JavaScript files)
// - `[]` to declare a range of characters to match in a path segment (e.g., `example.[0-9]` to match on `example.0`, `example.1`, …)
// - `[!...]` to negate a range of characters to match in a path segment (e.g., `example.[!0-9]` to match on `example.a`, `example.b`, but not `example.0`)
pub struct FileSystemWatcher {
	glob_pattern string [json: globPattern]
	kind         int
}

pub enum WatchKind {
	create = 1
	change = 2
	delete = 3
}

// method: ‘workspace/symbol’
// response: []SymbolInformation | null
pub struct WorkspaceSymbolParams {
	query string
}

// method: ‘workspace/executeCommand’
// response: any | null
pub struct ExecuteCommandParams {
	command   string
	arguments string [raw]
}

pub struct ExecuteCommandRegistrationOptions {
	command []string
}

// method: ‘workspace/applyEdit’
// response: ApplyWorkspaceEditResponse
//
pub struct ApplyWorkspaceEditParams {
	label string
	edit  WorkspaceEdit
}

pub struct ApplyWorkspaceEditResponse {
	applied        bool
	failure_reason string [json: failureReason]
}
