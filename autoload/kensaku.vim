" Legacy entry point of this plugin.
"
" Vim9 script functions must be named with a capital letter and cannot contain
" '#', so the legacy autoload names are defined here and forward to the Vim9
" implementation in autoload/kensaku/impl.vim.

function! kensaku#query(value) abort
  return kensaku#impl#Query(a:value)
endfunction

function! kensaku#reload() abort
  return kensaku#impl#Reload()
endfunction

" Searches the current buffer for the migemo regexp of {value}.
function! kensaku#search(value) abort
  let l:pattern = kensaku#query(a:value)
  if empty(l:pattern)
    echoerr 'kensaku: no pattern was generated for ' . string(a:value)
    return
  endif
  let @/ = l:pattern
  " The pattern may legitimately not match; that is not an error.
  silent! normal! n
endfunction
