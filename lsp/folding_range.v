module lsp

// method: ‘textDocument/foldingRange’
// response: []FoldingRange | none
pub struct FoldingRangeParams {
pub:
	text_document TextDocumentIdentifier [json: textDocument]
}

pub const (
	folding_range_kind_comment = 'comment'
	folding_range_kind_imports = 'imports'
	folding_range_kind_region  = 'region'
)

pub struct FoldingRange {
	start_line      int    [json: startLine]
	start_character int    [json: startCharacter]
	end_line        int    [json: endLine]
	end_character   int    [json: endCharacter]
	kind            string
}
