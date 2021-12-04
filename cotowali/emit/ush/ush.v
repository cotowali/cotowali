// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ush

import io
import encoding.base64
import cotowali.util { must_write }

pub struct Emitter {
mut:
	out io.Writer
}

[inline]
pub fn new_emitter(out io.Writer) Emitter {
	return Emitter{
		out: out
	}
}

pub struct Codes {
	sh   string
	pwsh string
}

pub fn (mut e Emitter) emit(codes Codes) {
	code := "
get-process > \${null:-/dev/null} 2>&1 && (invoke-expression @'
  # Powershell
  \$code_b64=\"${base64.encode_str(codes.pwsh)}\"
  \$code_bytes=[System.Convert]::FromBase64String(\$code_b64)
  \$code=[System.Text.Encoding]::Default.GetString(\$code_bytes)
  invoke-expression \$code
  exit 0
'@)

# posix sh
$codes.sh
"
	must_write(mut &e.out, code)
}
