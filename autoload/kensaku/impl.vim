vim9script
# Vim9 script implementation of the public API.

import './dictionary.vim' as kdict
import './migemo.vim' as kmigemo

var migemo: kmigemo.Migemo
var initialized = false

def Init()
  var cache = get(g:, 'kensaku_dictionary_cache', expand('~/.cache/kensaku.vim/migemo-compact-dict'))
  if !filereadable(cache)
    throw 'kensaku: dictionary not found: ' .. cache
  endif
  migemo = kmigemo.Migemo.new(kdict.CompactDictionary.Load(cache))
  initialized = true
enddef

# Returns a Vim regexp that matches the given roman query.
export def Query(value: string): string
  if !initialized
    Init()
  endif
  return migemo.Query(value)
enddef

# Drops the loaded dictionary so that the next query reloads it.
export def Reload()
  initialized = false
enddef
