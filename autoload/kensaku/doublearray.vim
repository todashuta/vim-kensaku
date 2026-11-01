vim9script
# Double array trie used by the romaji to hiragana converter.
# Ported from jsmigemo (https://github.com/oguna/jsmigemo, MIT License).
#
# jsmigemo's DoubleArray takes a character converter function.  The only
# converter used by RomajiProcessor2 is the identity function, so it is
# omitted here.

export class DoubleArray
  var base: list<number>
  var check: list<number>
  var charSize: number

  def new(this.base, this.check, this.charSize)
  enddef

  def Traverse(n: number, k: number): number
    if n < 0 || n >= len(this.base)
      return -1
    endif
    var m = this.base[n] + k
    if m < 0 || m >= len(this.check)
      return -1
    endif
    if this.check[m] == n
      return m
    endif
    return -1
  enddef

  def Lookup(str: string): number
    if str == ''
      return 0
    endif
    var n = 0
    for c in str2list(str)
      if c < 1
        throw 'kensaku: invalid character in romaji input'
      endif
      n = this.Traverse(n, c)
      if n == -1
        return -1
      endif
    endfor
    return n
  enddef

  def CommonPrefixSearch(key: string): list<number>
    var result: list<number> = []
    var codes = str2list(key)
    var index = 0
    var offset = 0
    while index != -1
      var lastIndex = index
      if offset == len(codes)
        index = -1
      else
        index = this.Traverse(index, codes[offset])
        offset += 1
      endif
      result->add(lastIndex)
    endwhile
    return result
  enddef

  def PredictiveSearch(key: string): list<number>
    var result: list<number> = []
    var n = this.Lookup(key)
    if n == -1
      return result
    endif
    this.VisitRecursive(n, result)
    return result
  enddef

  def VisitRecursive(n: number, result: list<number>)
    result->add(n)
    var i = 0
    while i < this.charSize
      var m = this.base[n] + i + 1
      if m >= len(this.check)
        return
      endif
      if this.check[m] == n
        this.VisitRecursive(m, result)
      endif
      i += 1
    endwhile
  enddef
endclass
