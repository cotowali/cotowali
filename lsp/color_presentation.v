module lsp

// /**
// * Color provider options.
// */
// export interface ColorProviderOptions {
// }
// method: ‘textDocument/colorPresentation’
// response: []ColorPresentation
pub struct ColorPresentationParams {
	text_document TextDocumentIdentifier [json: textDocument]
	color         Color
	range         Range
}

pub struct ColorPresentation {
	label                 string
	text_edit             TextEdit   [json: textEdit]
	additional_text_edits []TextEdit [json: additionalTextEdits]
}
