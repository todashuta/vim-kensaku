vim9script
# Migemo query -> Vim regexp converter.
# Ported from jsmigemo (https://github.com/oguna/jsmigemo, MIT License).

import './dictionary.vim' as kdict
import './romaji.vim' as kromaji
import './ternary.vim' as kternary
import './charset.vim' as kcharset

export class Migemo
  var dict: kdict.CompactDictionary
  var processor: kromaji.RomajiProcessor2
  var or: string = '\|'
  var beginGroup: string = '\%('
  var endGroup: string = '\)'
  var beginClass: string = '['
  var endClass: string = ']'
  var newline: string = ''
  var escape: string = '\\.[]*~^$'

  def new(this.dict)
    this.processor = kromaji.RomajiProcessor2.Build()
  enddef

  def SetRxop(or: string, beginGroup: string, endGroup: string, beginClass: string, endClass: string, newline: string, escape: string)
    this.or = or
    this.beginGroup = beginGroup
    this.endGroup = endGroup
    this.beginClass = beginClass
    this.endClass = endClass
    this.newline = newline
    this.escape = escape
  enddef

  # Splits a query into words the same way jsmigemo does: uppercase runs are
  # kept as words, lowercase ASCII runs are treated as roman input, and
  # anything else is passed through.
  def ParseQuery(query: string): list<string>
    var result: list<string> = []
    var re = '[^A-Z \t]\+\|[A-Z]\{2,}\|[A-Z][^A-Z \t]\+\|[A-Z][ \t]*$'
    var pos = 0
    var queryLen = len(query)
    while pos < queryLen
      var m = matchstrpos(query, re, pos)
      if m[1] < 0
        break
      endif
      result->add(m[0])
      pos = m[2]
    endwhile
    return result
  enddef

  def QueryAWord(word: string): string
    var generator = kternary.TernaryRegexGenerator.new(
      this.or, this.beginGroup, this.endGroup,
      this.beginClass, this.endClass, this.newline, this.escape,
    )
    generator.Add(word)
    var lower = tolower(word)
    for candidate in this.dict.PredictiveSearch(lower)
      generator.Add(candidate)
    endfor
    var zen = kcharset.Han2Zen(word)
    generator.Add(zen)
    generator.Add(kcharset.Zen2Han(zen))

    var hiraganaResult = this.processor.RomajiToHiraganaPredictively(lower)
    for suffix in hiraganaResult.suffixes
      var hira = hiraganaResult.prefix .. suffix
      generator.Add(hira)
      for candidate in this.dict.PredictiveSearch(hira)
        generator.Add(candidate)
      endfor
      var kata = kcharset.Hira2Kata(hira)
      generator.Add(kata)
      generator.Add(kcharset.Zen2Han(kata))
    endfor
    return generator.Generate()
  enddef

  def Query(word: string): string
    if word == ''
      return ''
    endif
    var result = ''
    for w in this.ParseQuery(word)
      result ..= this.QueryAWord(w)
    endfor
    return result
  enddef
endclass
