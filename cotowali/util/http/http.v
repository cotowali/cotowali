// Copyright (c) 2021-2023 zakuro <z@kuro.red>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module http

import os

pub struct Response {
pub:
	text        string
	status_code int
}

pub fn (r &Response) status() Status {
	return status_from_int(r.status_code)
}

fn curl_get(curl_path string, url string) ?Response {
	mut curl := os.new_process(curl_path)
	curl.set_args(['-sSL', url, '-w', '%{http_code}'])
	curl.set_redirect_stdio()
	curl.wait()
	output := curl.stdout_slurp()
	res_body := output[..output.len - 3]
	http_code := output[output.len - 3..].int()

	return Response{
		status_code: http_code
		text: res_body
	}
}

fn wget_get(wget_path string, url string) ?Response {
	mut wget := os.new_process(wget_path)
	wget.set_args(['-O', '-', '-S', '-q', '--header', 'Accept: */*', url])
	wget.set_redirect_stdio()
	wget.wait()

	res_body := wget.stdout_slurp()
	mut http_code := -1
	for line in wget.stderr_slurp().split_into_lines() {
		parts := line.trim_space().split(' ')
		// 'http/1.1 200 OK'.split(' ') == ['http/1.1', '200', 'OK']
		if parts.len > 2 && parts[0].to_upper().starts_with('HTTP') {
			n := parts[1].int()
			if (200 <= n && n < 300) || (400 <= n && n < 600) {
				http_code = n
			}
		}
	}

	return Response{
		status_code: http_code
		text: res_body
	}
}

pub fn get(url string) ?Response {
	if curl_path := os.find_abs_path_of_executable('curl') {
		return curl_get(curl_path, url)
	}
	if wget_path := os.find_abs_path_of_executable('wget') {
		return wget_get(wget_path, url)
	}
	eprintln('command not found: curl or wget is required')
	exit(127)
}
