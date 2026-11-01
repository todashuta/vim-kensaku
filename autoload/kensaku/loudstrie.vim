vim9script
# LOUDSTrie.
# Ported from jsmigemo (https://github.com/oguna/jsmigemo, MIT License).
#
# The JavaScript implementation uses generator functions, while Vim9 script
# does not have them.  Every traversal therefore collects its result into a
# list instead of yielding values.

import './bitvector.vim' as kbitvector

export class LOUDSTrie
  var bitVector: kbitvector.BitVector
  var edges: list<number> = []

  def new(this.bitVector, this.edges)
  enddef

  def Size(): number
    return len(this.edges) - 2
  enddef

  def Parent(x: number): number
    return this.bitVector.Rank(this.bitVector.Select(x, true), false)
  enddef

  def FirstChild(x: number): number
    var y = this.bitVector.Select(x, false) + 1
    if this.bitVector.Get(y)
      return this.bitVector.Rank(y, true) + 1
    endif
    return -1
  enddef

  def Traverse(index: number, c: number): number
    var firstChild = this.FirstChild(index)
    if firstChild == -1
      return -1
    endif
    var childStartBit = this.bitVector.Select(firstChild, true)
    var childEndBit = this.bitVector.NextClearBit(childStartBit)
    var childSize = childEndBit - childStartBit
    var result = LOUDSTrie.BinarySearch(this.edges, firstChild, firstChild + childSize, c)
    return result >= 0 ? result : -1
  enddef

  def Lookup(key: string): number
    var nodeIndex = 1
    for c in str2list(key)
      nodeIndex = this.Traverse(nodeIndex, c)
      if nodeIndex == -1
        break
      endif
    endfor
    return nodeIndex
  enddef

  def PredictiveSearch(index: number): list<number>
    var result: list<number> = []
    var lower = index
    var upper = index + 1
    while upper - lower > 0
      var i = lower
      while i < upper
        result->add(i)
        i += 1
      endwhile
      lower = this.bitVector.Rank(this.bitVector.Select(lower, false) + 1, true) + 1
      upper = this.bitVector.Rank(this.bitVector.Select(upper, false) + 1, true) + 1
    endwhile
    return result
  enddef

  def ReverseLookup(index: number): string
    var codes: list<number> = []
    var idx = index
    while idx > 1
      codes->add(this.edges[idx])
      idx = this.Parent(idx)
    endwhile
    return list2str(reverse(codes))
  enddef

  static def BinarySearch(a: list<number>, fromIndex: number, toIndex: number, key: number): number
    var low = fromIndex
    var high = toIndex - 1
    while low <= high
      var mid = (low + high) >> 1
      var midVal = a[mid]
      if midVal < key
        low = mid + 1
      elseif midVal > key
        high = mid - 1
      else
        return mid
      endif
    endwhile
    return -(low + 1)
  enddef
endclass
