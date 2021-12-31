// Copyright (c) 2021 zakuro <z@kuro.red>. All rights reserved.
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
module ush

import io
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
	// see https://github.com/cotowali/cotowali/issues/56#issuecomment-986142569

	sh_heredoc_tag := '__END_SH_HEREDOC_${util.rand<u64>()}'
	code := '
# polyglot (sh pwsh powershell.exe)

echo " \\`" > /dev/null # " @\'

# --- sh ---
$codes.sh
# ----------

: <<\'$sh_heredoc_tag\'
\'@ > \$null

# -- pwsh --
$codes.pwsh
# ----------

function ${sh_heredoc_tag}() {}

$sh_heredoc_tag

'
	must_write(mut &e.out, code)
}
