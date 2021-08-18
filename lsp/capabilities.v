module lsp

pub struct WorkspaceClientCapabilities {
pub mut:
	apply_edit               bool            [json: applyEdit]
	workspace_edit           WorkspaceEdit   [json: workspaceEdit]
	did_change_configuration DidChange       [json: didChangeConfiguration]
	did_change_watched_files DidChange       [json: didChangeWatchedFiles]
	symbol                   WorkspaceSymbol
	execute_command          DidChange       [json: executeCommand]
	workspace_folders        bool            [json: workspaceFolders]
	configuration            bool
}

pub struct WorkspaceSymbol {
pub mut:
	dynamic_registration bool     [json: dynamicRegistration]
	symbol_kind          ValueSet [json: symbolKind]
}

pub struct ValueSet {
pub mut:
	value_set []int [json: valueSet] // SymbolKind
}

pub struct DidChange {
pub mut:
	dynamic_registration bool [json: dynamicRegistration]
}

pub struct TextDocumentClientCapabilities {
pub mut:
	code_lens           Capability                  [json: codeLens]
	color_provider      Capability                  [json: colorProvider]
	completion          CompletionCapability
	declaration         LinkCapability
	definition          LinkCapability
	document_highlight  Capability                  [json: documentHighlight]
	document_link       Capability                  [json: documentLink]
	document_symbol     DocumentSymbolCapability    [json: documentSymbol]
	folding_range       FoldingRangeCapability      [json: foldingRange]
	formatting          Capability
	hover               HoverCapability
	implementation      LinkCapability
	on_type_formatting  Capability                  [json: on_type_formatting]
	publish_diagnostics PublishDiagnosticCapability [json: publishDiagnostics]
	range_formatting    Capability                  [json: rangeFormatting]
	references          Capability
	rename              RenameCapability
	selection_range     Capability                  [json: selectionRange]
	signature_help      SignatureHelpCapability
	synchronization     TextDocumentSyncCapability
	type_definition     LinkCapability              [json: typeDefinition]
}

pub struct DocumentLinkSupport {
	dynamic_registration bool [json: dynamicRegistration]
	tooltip_support      bool [json: tooltip_support]
}

pub struct TextDocumentSyncCapability {
pub mut:
	dynamic_registration bool [json: dynamicRegistration]
	will_save            bool [json: willSave]
	will_save_wait_until bool [json: willSaveWaitUntil]
	did_save             bool [json: didSave]
}

pub struct CompletionCapability {
pub mut:
	dynamic_registration bool                   [json: dynamicRegistration]
	completion_item      CompletionItemSettings [json: completionItem]
	completion_item_kind ValueSet               [json: completionItemKind]
	context_support      bool                   [json: contextSupport]
}

pub struct HoverCapability {
pub mut:
	dynamic_registration bool     [json: dynamicRegistration]
	content_format       []string [json: contentFormat] // MarkupKind
}

pub struct SignatureHelpCapability {
pub mut:
	dynamic_registration  bool                           [json: dynamicRegistration]
	signature_information SignatureInformationCapability [json: signatureInformation]
}

pub struct SignatureInformationCapability {
pub mut:
	document_format []string [json: documentFormat]
	// MarkupKind
	parameter_information ParamsInfo [json: parameterInformation]
}

pub struct ParamsInfo {
pub mut:
	label_offset_support bool [json: labelOffsetSupport]
}

pub struct Capability {
pub mut:
	dynamic_registration bool [json: dynamicRegistration]
}

pub struct DocumentSymbolCapability {
pub mut:
	dynamic_registration                 bool     [json: dynamicRegistration]
	symbol_kind                          ValueSet [json: symbolKind]
	hierarchical_document_symbol_support bool     [json: hierarchicalDocumentSymbolSupport]
}

pub struct LinkCapability {
pub mut:
	dynamic_registration bool [json: dynamicRegistration]
	link_support         bool [json: linkSupport]
}

pub struct CodeActionCapability {
pub mut:
	dynamic_registration        bool                     [json: dynamicRegistration]
	is_preferred_support        bool                     [json: isPreferredSupport]
	code_action_literal_support CodeActionLiteralSupport [json: codeActionLiteralSupport]
}

pub struct CodeActionLiteralSupport {
pub mut:
	code_action_kind CodeActionKindF [json: codeActionKind]
}

pub struct CodeActionKindF {
pub mut:
	value_set []string [json: valueSet]
}

pub struct RenameCapability {
pub mut:
	dynamic_registration bool [json: dynamicRegistration]
	prepare_support      bool [json: prepareSupport]
}

pub struct PublishDiagnosticCapability {
pub mut:
	related_information bool     [json: relatedInformation]
	version_support     bool     [json: versionSupport]
	tag_support         ValueSet [json: tagSupport]
}

pub struct FoldingRangeCapability {
pub mut:
	dynamic_registration bool [json: dynamicRegistration]
	range_limit          int  [json: rangeLimit]
	line_folding_only    bool [json: lineFoldingOnly]
}

pub struct ClientCapabilities {
pub mut:
	workspace     WorkspaceClientCapabilities
	text_document TextDocumentClientCapabilities [json: textDocument]
	window        WindowCapability
	experimental  string                         [raw]
}

pub struct WindowCapability {
pub mut:
	work_done_progress bool [json: workDoneProgress]
}

pub struct ServerCapabilities {
pub mut:
	// text_document_sync TextDocumentSyncOptions [json:textDocumentSync]
	text_document_sync                   int                             [json: textDocumentSync]
	hover_provider                       bool                            [json: hoverProvider]
	completion_provider                  CompletionOptions               [json: completionProvider]
	signature_help_provider              SignatureHelpOptions            [json: signatureHelpProvider]
	definition_provider                  bool                            [json: definitionProvider]
	type_definition_provider             bool                            [json: typeDefinitionProvider]
	implementation_provider              bool                            [json: implementationProvider]
	references_provider                  bool                            [json: referencesProvider]
	document_highlight_provider          bool                            [json: documentHightlightProvider]
	document_symbol_provider             bool                            [json: documentSymbolProvider]
	workspace_symbol_provider            bool                            [json: workspaceSymbolProvider]
	code_action_provider                 bool                            [json: codeActionProvider]
	code_lens_provider                   CodeLensOptions                 [json: codeLensProvider]
	document_formatting_provider         bool                            [json: documentFormattingProvider]
	document_on_type_formatting_provider DocumentOnTypeFormattingOptions [json: documentOnTypeFormattingProvider]
	rename_provider                      bool                            [json: renameProvider]
	document_link_provider               bool                            [json: documentLinkProvider]
	color_provider                       bool                            [json: colorProvider]
	declaration_provider                 bool                            [json: declarationProvider]
	execute_command_provder              string                          [json: executeCommandProvider; raw]
	folding_range_provider               bool                            [json: foldingRangeProvider]
	experimental                         map[string]bool
}

pub struct ServerCapabilitiesWorkspace {
pub mut:
	workspace_folders WorkspaceFoldersProviderSupport [json: WorkspaceFoldersProviderSupport]
}

pub struct WorkspaceFoldersProviderSupport {
pub mut:
	supported            bool
	change_notifications string [json: changeNotifications]
}
