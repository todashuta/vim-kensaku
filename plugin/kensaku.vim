vim9script
# kensaku.vim - Migemo for Vim9 script
#
# This plugin is loaded at startup.  The dictionary itself is loaded lazily on
# the first query so that Vim's startup time is not affected.

if exists('g:loaded_kensaku')
  finish
endif
g:loaded_kensaku = true

if !exists('g:kensaku_dictionary_url')
  g:kensaku_dictionary_url = 'https://github.com/oguna/migemo-compact-dict-latest/releases/download/v0.2/migemo-compact-dict'
endif
if !exists('g:kensaku_dictionary_cache')
  g:kensaku_dictionary_cache = expand('~/.cache/kensaku.vim/migemo-compact-dict')
endif

if !exists(':Kensaku')
  command! -nargs=1 -bar Kensaku call kensaku#search(<q-args>)
endif
