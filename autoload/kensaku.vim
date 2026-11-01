" Legacy entry point of this plugin.
"
" Vim9 script functions must be named with a capital letter and cannot contain
" '#', so the legacy autoload names are defined here and forward to the Vim9
" implementation in autoload/kensaku/impl.vim.

" g:kensaku#rxop#vim is a variable and is not loaded by the autoload mechanism.
" Load the presets here as well so that kensaku#query() works even when the
" plugin script has not been sourced.
runtime autoload/kensaku/rxop.vim

" Returns a regexp for {value}.  An optional {option} dictionary accepts an
" "rxop" entry, which may be a dictionary or a legacy list.  The preset
" g:kensaku#rxop#vim is used by default.
function! kensaku#query(value, ...) abort
  let l:option = extend({'rxop': g:kensaku#rxop#vim}, a:0 ? a:1 : {})
  return kensaku#impl#Query(a:value, s:normalize_rxop(l:option.rxop))
endfunction

" Synchronous compatibility version of kensaku#query().  The Vim9 script
" implementation is fast enough that the callback runs immediately.
function! kensaku#query_async(value, success, ...) abort
  let l:option = a:0 ? a:1 : {}
  let l:Failure = get(l:option, 'failure', funcref('s:failure'))
  try
    return a:success(kensaku#query(a:value, l:option))
  catch
    return l:Failure(v:exception)
  endtry
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

function! s:failure(err) abort
  echoerr a:err
endfunction

" Normalizes an "rxop" entry into a dictionary.  The legacy list forms
" [or, startGroup, endGroup, startClass, endClass, newline] and
" [prefix, or, startGroup, endGroup, startClass, endClass, newline] are still
" accepted.  Their escape is always the jsmigemo default.
function! s:normalize_rxop(rxop) abort
  if type(a:rxop) == v:t_dict
    return a:rxop
  endif
  if type(a:rxop) != v:t_list
    throw 'kensaku: invalid rxop: ' . string(a:rxop)
  endif
  if len(a:rxop) == 6
    let l:prefix = ''
    let l:rest = a:rxop
  elseif len(a:rxop) == 7
    let l:prefix = a:rxop[0]
    let l:rest = a:rxop[1:]
  else
    throw 'kensaku: invalid rxop: ' . string(a:rxop)
  endif
  return {
        \ 'prefix': l:prefix,
        \ 'or': l:rest[0],
        \ 'startGroup': l:rest[1],
        \ 'endGroup': l:rest[2],
        \ 'startClass': l:rest[3],
        \ 'endClass': l:rest[4],
        \ 'newline': l:rest[5],
        \ 'escape': '\\.[]{}()*+-?^$|',
        \}
endfunction
