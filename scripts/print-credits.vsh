#!/usr/bin/env -S v run

import arrays
import net.http

struct License {
	title       string
	url         string
	license_url string
mut:
	content string
}

fn license(v License) License {
	return License{
		...v
		content: (http.get(v.license_url) or { panic(err) }).text
	}
}

fn (v License) max_line_len() int {
	return arrays.max([
		v.title.len,
		v.url.len,
		arrays.max(v.content.split_into_lines().map(it.len)),
	])
}

fn print_credits(licenses []License) {
	divider_len := arrays.max(licenses.map(it.max_line_len()))
	for v in licenses {
		println(v.title)
		println(v.url)
		println('-'.repeat(divider_len))
		print(v.content)
		println('='.repeat(divider_len))
	}
}

// --

print_credits([
	license(
		title: 'The V Programming Language'
		url: 'https://vlang.io'
		license_url: 'https://raw.githubusercontent.com/vlang/v/master/LICENSE'
	),
	license(
		title: 'V Language Server'
		url: 'https://github.com/vlang/vls'
		license_url: 'https://raw.githubusercontent.com/vlang/vls/use-tree-sitter/LICENSE'
	),
])
