vim9script
# Vim9 script implementation of the public API.

import './dictionary.vim' as kdict
import './migemo.vim' as kmigemo

var migemo: kmigemo.Migemo
var initialized = false
var appliedRxop = ''

# Builds a stable key from the entries of {rxop}.  string() cannot be used
# because it depends on the insertion order of the dictionary.
def RxopKey(rxop: dict<string>): string
  return join([
    get(rxop, 'or', ''),
    get(rxop, 'startGroup', ''),
    get(rxop, 'endGroup', ''),
    get(rxop, 'startClass', ''),
    get(rxop, 'endClass', ''),
    get(rxop, 'newline', ''),
    get(rxop, 'escape', ''),
  ], "\n")
enddef

def ApplyRxop(rxop: dict<string>)
  migemo.SetRxop(
    get(rxop, 'or', '\|'),
    get(rxop, 'startGroup', '\%('),
    get(rxop, 'endGroup', '\)'),
    get(rxop, 'startClass', '['),
    get(rxop, 'endClass', ']'),
    get(rxop, 'newline', ''),
    get(rxop, 'escape', '\\.[]*~^$'),
  )
  appliedRxop = RxopKey(rxop)
enddef

def Init(rxop: dict<string>)
  var cache = get(g:, 'kensaku_dictionary_cache', expand('~/.cache/kensaku.vim/migemo-compact-dict'))
  if !filereadable(cache)
    throw 'kensaku: dictionary not found: ' .. cache
  endif
  migemo = kmigemo.Migemo.new(kdict.CompactDictionary.Load(cache))
  initialized = true
  appliedRxop = ''
  ApplyRxop(rxop)
enddef

# Returns a regexp that matches the given roman query.  The "prefix" entry of
# {rxop} is prepended to the result, so the default rxop yields a regexp that
# starts with "\m".
export def Query(value: string, rxop: dict<string> = {}): string
  if !initialized
    Init(rxop)
  endif
  if RxopKey(rxop) != appliedRxop
    ApplyRxop(rxop)
  endif
  if value == ''
    return ''
  endif
  return get(rxop, 'prefix', '') .. migemo.Query(value)
enddef

# Drops the loaded dictionary so that the next query reloads it.
export def Reload()
  initialized = false
  appliedRxop = ''
enddef
