vim9script
# Ternary search tree based migemo regex generator.
# Ported from jsmigemo (https://github.com/oguna/jsmigemo, MIT License).
#
# jsmigemo represents tree nodes as objects with nullable pointers.  Vim9
# script has no null value, so nodes are stored in one flat number list and
# referred to by their index; index 0 means "no node".  A node occupies
# NODE_SIZE slots: value, child, left, right, level.

const NODE_SIZE = 5

export class TernaryRegexGenerator
  var or: string
  var beginGroup: string
  var endGroup: string
  var beginClass: string
  var endClass: string
  var newline: string
  var escaped: list<bool>
  var nodes: list<number> = [0, 0, 0, 0, 0]
  var root: number = 0
  var lastTarget: number = 0
  var lastInserted: number = 0

  def new(this.or, this.beginGroup, this.endGroup, this.beginClass, this.endClass, this.newline, escape: string)
    this.escaped = repeat([false], 128)
    var escapeLen = strchars(escape)
    var i = 0
    while i < escapeLen
      var c = char2nr(strcharpart(escape, i, 1))
      if c >= 128
        throw 'kensaku: only ASCII characters can be escaped'
      endif
      this.escaped[c] = true
      i += 1
    endwhile
  enddef

  def Value(node: number): number
    return this.nodes[node * NODE_SIZE]
  enddef

  def Child(node: number): number
    return this.nodes[node * NODE_SIZE + 1]
  enddef

  def Left(node: number): number
    return this.nodes[node * NODE_SIZE + 2]
  enddef

  def Right(node: number): number
    return this.nodes[node * NODE_SIZE + 3]
  enddef

  def Level(node: number): number
    return this.nodes[node * NODE_SIZE + 4]
  enddef

  def SetChild(node: number, value: number)
    this.nodes[node * NODE_SIZE + 1] = value
  enddef

  def SetLeft(node: number, value: number)
    this.nodes[node * NODE_SIZE + 2] = value
  enddef

  def SetRight(node: number, value: number)
    this.nodes[node * NODE_SIZE + 3] = value
  enddef

  def SetLevel(node: number, value: number)
    this.nodes[node * NODE_SIZE + 4] = value
  enddef

  def NewNode(value: number): number
    var index = len(this.nodes) / NODE_SIZE
    this.nodes->extend([value, 0, 0, 0, 1])
    return index
  enddef

  # Inserts x into the subtree and returns the new subtree root.  The node to
  # attach a child to is reported through this.lastTarget/this.lastInserted
  # instead of a list tuple: allocating a list for every recursive step was
  # the dominant cost of building large trees.
  def Insert(x: number, tArg: number): number
    var t = tArg
    if t == 0
      var node = this.NewNode(x)
      this.lastTarget = node
      this.lastInserted = 1
      return node
    endif
    var base = t * NODE_SIZE
    var tv = this.nodes[base]
    if x < tv
      this.nodes[base + 2] = this.Insert(x, this.nodes[base + 2])
    elseif x > tv
      this.nodes[base + 3] = this.Insert(x, this.nodes[base + 3])
    else
      this.lastTarget = t
      this.lastInserted = 0
      return t
    endif
    t = this.Skew(t)
    t = this.Split(t)
    return t
  enddef

  def Skew(t: number): number
    if t == 0
      return 0
    endif
    var base = t * NODE_SIZE
    var l = this.nodes[base + 2]
    if l == 0
      return t
    endif
    var lbase = l * NODE_SIZE
    if this.nodes[lbase + 4] == this.nodes[base + 4]
      this.nodes[base + 2] = this.nodes[lbase + 3]
      this.nodes[lbase + 3] = t
      return l
    endif
    return t
  enddef

  def Split(t: number): number
    if t == 0
      return 0
    endif
    var base = t * NODE_SIZE
    var r = this.nodes[base + 3]
    if r == 0
      return t
    endif
    var rbase = r * NODE_SIZE
    var rr = this.nodes[rbase + 3]
    if rr == 0
      return t
    endif
    if this.nodes[base + 4] == this.nodes[rr * NODE_SIZE + 4]
      this.nodes[base + 3] = this.nodes[rbase + 2]
      this.nodes[rbase + 2] = t
      this.nodes[rbase + 4] = this.nodes[rbase + 4] + 1
      return r
    endif
    return t
  enddef

  def AddImpl(node: number, codes: list<number>, offset: number): number
    if offset < len(codes)
      var newNode = this.Insert(codes[offset], node)
      var target = this.lastTarget
      var inserted = this.lastInserted
      var child = this.nodes[target * NODE_SIZE + 1]
      if inserted != 0 || child != 0
        this.nodes[target * NODE_SIZE + 1] = this.AddImpl(child, codes, offset + 1)
      endif
      return newNode
    endif
    return 0
  enddef

  def Add(word: string)
    if word == ''
      return
    endif
    this.root = this.AddImpl(this.root, str2list(word), 0)
  enddef

  def Siblings(node: number): list<number>
    var result: list<number> = []
    this.CollectSiblings(node, result)
    return result
  enddef

  def CollectSiblings(node: number, result: list<number>)
    if node != 0
      this.CollectSiblings(this.Left(node), result)
      result->add(node)
      this.CollectSiblings(this.Right(node), result)
    endif
  enddef

  def GenerateStub(node: number): string
    var buf = ''
    var siblings = this.Siblings(node)
    var brother = len(siblings)
    var haschild = 0
    for n in siblings
      if this.Child(n) != 0
        haschild += 1
      endif
    endfor
    var nochild = brother - haschild

    if brother > 1 && haschild > 0
      buf ..= this.beginGroup
    endif

    if nochild > 0
      if nochild > 1
        buf ..= this.beginClass
      endif
      for n in siblings
        if this.Child(n) != 0
          continue
        endif
        var v = this.Value(n)
        if v < 128 && this.escaped[v]
          buf ..= '\'
        endif
        buf ..= nr2char(v)
      endfor
      if nochild > 1
        buf ..= this.endClass
      endif
    endif

    if haschild > 0
      if nochild > 0
        buf ..= this.or
      endif
      for n in siblings
        if this.Child(n) == 0
          continue
        endif
        var v = this.Value(n)
        if v < 128 && this.escaped[v]
          buf ..= '\'
        endif
        buf ..= nr2char(v)
        buf ..= this.newline
        buf ..= this.GenerateStub(this.Child(n))
        if haschild > 1
          buf ..= this.or
        endif
      endfor
      if haschild > 1
        buf = strpart(buf, 0, len(buf) - len(this.or))
      endif
    endif

    if brother > 1 && haschild > 0
      buf ..= this.endGroup
    endif
    return buf
  enddef

  def Generate(): string
    if this.root == 0
      return ''
    endif
    return this.GenerateStub(this.root)
  enddef
endclass
