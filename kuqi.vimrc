" vim-lsp configuration to debugging kuqi. Load this file in your vimrc if you want use.
call lsp#register_server({
  \ 'name': 'kuqi',
  \ 'cmd': { server_info->['kuqi'] },
  \ 'allowlist': ['cotowali'],
  \ 'languageId': { server_info ->'kuqi' },
  \ })
let g:lsp_log_file = expand('vim-lsp.log')
let g:lsp_show_message_log_level = 'log'
