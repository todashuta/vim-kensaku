vim9script
# Character width / kana conversions used by migemo.
# Ported from jsmigemo (https://github.com/oguna/jsmigemo, MIT License).

import './charset_table.vim' as ktable

export def Han2Zen(source: string): string
  var result: list<string> = []
  for c in split(source, '\zs')
    result->add(get(ktable.HAN2ZEN, c, c))
  endfor
  return join(result, '')
enddef

export def Zen2Han(source: string): string
  var result: list<string> = []
  for c in split(source, '\zs')
    result->add(get(ktable.ZEN2HAN, c, c))
  endfor
  return join(result, '')
enddef

export def Hira2Kata(source: string): string
  var result: list<string> = []
  for c in split(source, '\zs')
    var n = char2nr(c)
    if n >= 0x3041 && n <= 0x3096
      result->add(nr2char(n - 0x3041 + 0x30a1))
    else
      result->add(c)
    endif
  endfor
  return join(result, '')
enddef
