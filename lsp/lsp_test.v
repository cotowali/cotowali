module lsp

fn test_document_uri_from_path() {
	input := '/foo/bar/test.v'
	assert document_uri_from_path(input) == 'file:///foo/bar/test.v'
}

fn test_document_uri_path() {
	uri := DocumentUri('file:///baz/foo/hello.v')
	expected := '/baz/foo/hello.v'
	assert uri.path() == expected
}
