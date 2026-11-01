vim9script
# Romaji to hiragana converter (double array trie based).
# Ported from jsmigemo (https://github.com/oguna/jsmigemo, MIT License).
#
# The tables are generated from jsmigemo's RomajiProcessor2 by
# tools/generate-tables.py.  Vim9 script strings are counted in characters,
# while jsmigemo counts UTF-16 code units; for the BMP characters used here
# both counts are identical.

import './doublearray.vim' as kdoublearray
import './romaji_table.vim' as ktable

export class RomajiProcessor2
  var trie: kdoublearray.DoubleArray
  var hiraganaList: list<string>
  var remainList: list<number>

  def new(this.trie, this.hiraganaList, this.remainList)
  enddef

  static def Build(): RomajiProcessor2
    return RomajiProcessor2.new(kdoublearray.DoubleArray.new(ktable.BASE, ktable.CHECK, 128), ktable.HIRAGANA, ktable.REMAIN)
  enddef

  def RomajiToHiragana(romaji: string): string
    var buffer = ''
    var cursor = 0
    var romajiLen = strchars(romaji)
    while cursor < romajiLen
      var longestNode = -1
      var count = -1
      for node in this.trie.CommonPrefixSearch(strcharpart(romaji, cursor))
        if this.remainList[node] != -1
          longestNode = node
        endif
        count += 1
      endfor
      if longestNode == -1
        buffer ..= strcharpart(romaji, cursor, 1)
        cursor += 1
      else
        buffer ..= this.hiraganaList[longestNode]
        cursor = cursor + count - this.remainList[longestNode]
      endif
    endwhile
    return buffer
  enddef

  # Returns the fixed prefix and the list of possible completions of the last
  # (possibly incomplete) syllable.
  def RomajiToHiraganaPredictively(romaji: string): dict<any>
    var builder = ''
    var cursor = 0
    var romajiLen = strchars(romaji)
    while cursor < romajiLen
      var longestNode = -1
      var count = 0
      var rest = strcharpart(romaji, cursor)
      for node in this.trie.CommonPrefixSearch(rest)
        if this.remainList[node] != -1
          longestNode = node
        endif
        count += 1
      endfor
      if count + cursor - 1 == romajiLen
        # The input ends in the middle of a syllable: enumerate candidates.
        var seen: dict<bool> = {}
        var candidates: list<string> = []
        for node in this.trie.PredictiveSearch(rest)
          if this.remainList[node] != -1
            var h = this.hiraganaList[node]
            if !has_key(seen, h)
              seen[h] = true
              candidates->add(h)
            endif
          endif
        endfor
        if len(candidates) == 1
          return {prefix: builder .. candidates[0], suffixes: ['']}
        endif
        return {prefix: builder, suffixes: candidates}
      elseif longestNode >= 0
        builder ..= this.hiraganaList[longestNode]
        cursor = cursor + count - 1 - this.remainList[longestNode]
      else
        builder ..= strcharpart(romaji, cursor, 1)
        cursor += 1
      endif
    endwhile
    return {prefix: builder, suffixes: ['']}
  enddef
endclass
