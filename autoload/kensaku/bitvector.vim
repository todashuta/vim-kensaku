vim9script
# Bit vector with rank/select support.
# Ported from jsmigemo (https://github.com/oguna/jsmigemo, MIT License).
#
# Note: Vim9 script has no symbolic bitwise operators; and(), or() and
# invert() are used instead.

export class BitVector
  var bits: list<number> = []
  var sizeInBits: number = 0
  var lb: list<number> = []
  var sb: list<number> = []

  def new(this.bits, this.sizeInBits)
    var lbLen = (this.sizeInBits + 511) >> 9
    this.lb = repeat([0], lbLen)
    this.sb = repeat([0], lbLen * 8)
    var sum = 0
    var sumInLb = 0
    var halfLen = len(this.bits) >> 1
    var i = 0
    while i < len(this.sb)
      var bc = 0
      if i < halfLen
        bc = BitVector.BitCount(this.bits[i * 2]) + BitVector.BitCount(this.bits[i * 2 + 1])
      endif
      this.sb[i] = sumInLb
      sumInLb += bc
      if i % 8 == 7
        this.lb[i >> 3] = sum
        sum += sumInLb
        sumInLb = 0
      endif
      i += 1
    endwhile
  enddef

  static def BitCount(i: number): number
    var x = and(i, 0xffffffff)
    x = x - and(x >> 1, 0x55555555)
    x = and(x, 0x33333333) + and(x >> 2, 0x33333333)
    x = and(x + (x >> 4), 0x0f0f0f0f)
    x = x + (x >> 8)
    x = x + (x >> 16)
    return and(x, 0x3f)
  enddef

  static def NumberOfTrailingZeros(i: number): number
    if i == 0
      return 32
    endif
    var n = 0
    var x = and(i, 0xffffffff)
    while and(x, 1) == 0
      x = x >> 1
      n += 1
    endwhile
    return n
  enddef

  def Size(): number
    return this.sizeInBits
  enddef

  def Get(pos: number): bool
    return and(this.bits[pos >> 5] >> (pos % 32), 1) == 1
  enddef

  def Rank(pos: number, b: bool): number
    var count1 = this.sb[pos >> 6] + this.lb[pos >> 9]
    var posInDWord = pos % 64
    if posInDWord >= 32
      count1 += BitVector.BitCount(this.bits[and(pos >> 5, 0xfffffffe)])
    endif
    var posInWord = pos % 32
    var mask = 0x7fffffff >> (31 - posInWord)
    count1 += BitVector.BitCount(and(this.bits[pos >> 5], mask))
    return b ? count1 : (pos - count1)
  enddef

  def NextClearBit(fromIndex: number): number
    var u = fromIndex >> 5
    var word = and(and(invert(this.bits[u]), 0xffffffff), and(0xffffffff << (fromIndex % 32), 0xffffffff))
    while true
      if word != 0
        return u * 32 + BitVector.NumberOfTrailingZeros(word)
      endif
      u += 1
      if u == len(this.bits)
        return -1
      endif
      word = and(invert(this.bits[u]), 0xffffffff)
    endwhile
    return -1
  enddef

  def Select(count: number, b: bool): number
    var lbIndex = this.LowerBoundBinarySearchLB(count, b) - 1
    if lbIndex == -1
      return 0
    endif
    var countInLb = count - (b ? this.lb[lbIndex] : (512 * lbIndex - this.lb[lbIndex]))
    var sbIndex = this.LowerBoundBinarySearchSB(countInLb, lbIndex * 8, lbIndex * 8 + 8, b) - 1
    var countInSb = countInLb - (b ? this.sb[sbIndex] : (64 * (sbIndex % 8) - this.sb[sbIndex]))
    var wordL = this.bits[sbIndex * 2]
    var wordU = this.bits[sbIndex * 2 + 1]
    if !b
      wordL = and(invert(wordL), 0xffffffff)
      wordU = and(invert(wordU), 0xffffffff)
    endif
    var lowerBitCount = BitVector.BitCount(wordL)
    var i = 0
    if countInSb > lowerBitCount
      wordL = wordU
      countInSb -= lowerBitCount
      i = 32
    endif
    while countInSb > 0
      countInSb -= and(wordL, 1)
      wordL = wordL >> 1
      i += 1
    endwhile
    return sbIndex * 64 + (i - 1)
  enddef

  def LowerBoundBinarySearchLB(key: number, b: bool): number
    var high = len(this.lb)
    var low = -1
    while high - low > 1
      var mid = (high + low) >> 1
      var value = b ? this.lb[mid] : (512 * mid - this.lb[mid])
      if value < key
        low = mid
      else
        high = mid
      endif
    endwhile
    return high
  enddef

  def LowerBoundBinarySearchSB(key: number, fromIndex: number, toIndex: number, b: bool): number
    var high = toIndex
    var low = fromIndex - 1
    while high - low > 1
      var mid = (high + low) >> 1
      var value = b ? this.sb[mid] : (64 * (mid % 8) - this.sb[mid])
      if value < key
        low = mid
      else
        high = mid
      endif
    endwhile
    return high
  enddef
endclass
