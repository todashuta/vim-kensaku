vim9script
# Compact migemo dictionary (LOUDSTrie based).
# Ported from jsmigemo (https://github.com/oguna/jsmigemo, MIT License).
#
# The on-disk format is the one produced by jsmigemo's CompactDictionaryBuilder.
# All integers in the file are big-endian.

import './bitvector.vim' as kbitvector
import './loudstrie.vim' as kloudstrie

export class CompactDictionary
  var keyTrie: kloudstrie.LOUDSTrie
  var valueTrie: kloudstrie.LOUDSTrie
  var mappingBitVector: kbitvector.BitVector
  var mapping: list<number> = []
  var hasMappingWords: list<number> = []

  static def ReadU32(bytes: list<number>, off: number): number
    return (bytes[off] << 24) + (bytes[off + 1] << 16) + (bytes[off + 2] << 8) + bytes[off + 3]
  enddef

  static def ReadI32(bytes: list<number>, off: number): number
    var v = (bytes[off] << 24) + (bytes[off + 1] << 16) + (bytes[off + 2] << 8) + bytes[off + 3]
    return v >= 0x80000000 ? v - 0x100000000 : v
  enddef

  # Compact hiragana is a 1-byte encoding of ASCII, hiragana and the long
  # vowel mark used by the key trie.
  static def DecodeCompactHiragana(c: number): number
    if c == 0x00
      return 0
    elseif c >= 0x20 && c <= 0x7e
      return c
    elseif c >= 0xa1 && c <= 0xf6
      return c + 0x3040 - 0xa0
    elseif c == 0xf7
      return 0x30fc
    endif
    throw 'kensaku: invalid compact hiragana byte: ' .. c
  enddef

  static def ReadTrie(bytes: list<number>, offset: number, compact: bool): dict<any>
    var off = offset
    var edgeSize = CompactDictionary.ReadI32(bytes, off)
    off += 4
    var edges = repeat([0], edgeSize)
    var i = 0
    if compact
      while i < edgeSize
        edges[i] = CompactDictionary.DecodeCompactHiragana(bytes[off])
        off += 1
        i += 1
      endwhile
    else
      while i < edgeSize
        edges[i] = (bytes[off] << 8) + bytes[off + 1]
        off += 2
        i += 1
      endwhile
    endif
    var bvSize = CompactDictionary.ReadU32(bytes, off)
    off += 4
    var wordCount = ((bvSize + 63) >> 6) * 2
    var words = repeat([0], wordCount)
    var p = 0
    var nPairs = wordCount >> 1
    while p < nPairs
      words[p * 2 + 1] = CompactDictionary.ReadU32(bytes, off)
      off += 4
      words[p * 2] = CompactDictionary.ReadU32(bytes, off)
      off += 4
      p += 1
    endwhile
    var result: dict<any> = {
      trie: kloudstrie.LOUDSTrie.new(kbitvector.BitVector.new(words, bvSize), edges),
      offset: off,
    }
    return result
  enddef

  static def ReadBitVector(bytes: list<number>, offset: number): dict<any>
    var off = offset
    var size = CompactDictionary.ReadU32(bytes, off)
    off += 4
    var wordCount = ((size + 63) >> 6) * 2
    var words = repeat([0], wordCount)
    var p = 0
    var nPairs = wordCount >> 1
    while p < nPairs
      words[p * 2 + 1] = CompactDictionary.ReadU32(bytes, off)
      off += 4
      words[p * 2] = CompactDictionary.ReadU32(bytes, off)
      off += 4
      p += 1
    endwhile
    return {bitVector: kbitvector.BitVector.new(words, size), offset: off}
  enddef

  static def Load(path: string): CompactDictionary
    var bytes = blob2list(readblob(path))
    var offset = 0
    var keyResult = CompactDictionary.ReadTrie(bytes, offset, true)
    offset = keyResult.offset
    var valueResult = CompactDictionary.ReadTrie(bytes, offset, false)
    offset = valueResult.offset

    var mbvResult = CompactDictionary.ReadBitVector(bytes, offset)
    offset = mbvResult.offset
    var mappingBitVector: kbitvector.BitVector = mbvResult.bitVector

    var mappingSize = CompactDictionary.ReadU32(bytes, offset)
    offset += 4
    var mapping = repeat([0], mappingSize)
    var i = 0
    while i < mappingSize
      mapping[i] = CompactDictionary.ReadI32(bytes, offset)
      offset += 4
      i += 1
    endwhile

    # The mapping bit vector stores, for every key node, a run of set bits
    # followed by a clear bit.  Collect the "has any value" flag per node so
    # lookups do not have to walk the bit vector twice.
    var numOfNodes = mappingBitVector.Rank(mappingBitVector.Size() + 1, false)
    var hmWords = repeat([0], (numOfNodes + 31) >> 5)
    var bitPosition = 0
    var node = 1
    while node < numOfNodes
      if mappingBitVector.Get(bitPosition + 1)
        hmWords[node >> 5] = or(hmWords[node >> 5], 1 << (node % 32))
      endif
      bitPosition = mappingBitVector.NextClearBit(bitPosition + 1)
      node += 1
    endwhile

    var dict = CompactDictionary.new(
      keyResult.trie,
      valueResult.trie,
      mappingBitVector,
      mapping,
    )
    dict.hasMappingWords = hmWords
    return dict
  enddef

  def HasMapping(node: number): bool
    return and(this.hasMappingWords[node >> 5] >> (node % 32), 1) == 1
  enddef

  def Search(key: string): list<string>
    var result: list<string> = []
    var keyIndex = this.keyTrie.Lookup(key)
    if keyIndex != -1 && this.HasMapping(keyIndex)
      var valueStartPos = this.mappingBitVector.Select(keyIndex, false)
      var valueEndPos = this.mappingBitVector.NextClearBit(valueStartPos + 1)
      var size = valueEndPos - valueStartPos - 1
      if size > 0
        var offset = this.mappingBitVector.Rank(valueStartPos, false)
        var i = 0
        while i < size
          result->add(this.valueTrie.ReverseLookup(this.mapping[valueStartPos - offset + i]))
          i += 1
        endwhile
      endif
    endif
    return result
  enddef

  def PredictiveSearch(key: string): list<string>
    var result: list<string> = []
    var keyIndex = this.keyTrie.Lookup(key)
    if keyIndex > 1
      for node in this.keyTrie.PredictiveSearch(keyIndex)
        if this.HasMapping(node)
          var valueStartPos = this.mappingBitVector.Select(node, false)
          var valueEndPos = this.mappingBitVector.NextClearBit(valueStartPos + 1)
          var size = valueEndPos - valueStartPos - 1
          var offset = this.mappingBitVector.Rank(valueStartPos, false)
          var j = 0
          while j < size
            result->add(this.valueTrie.ReverseLookup(this.mapping[valueStartPos - offset + j]))
            j += 1
          endwhile
        endif
      endfor
    endif
    return result
  enddef
endclass
