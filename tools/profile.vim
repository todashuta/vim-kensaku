vim9script
import '../autoload/kensaku/dictionary.vim' as kdict
import '../autoload/kensaku/romaji.vim' as kromaji
import '../autoload/kensaku/ternary.vim' as kternary

var out: list<string> = []
var dictPath = $KENSHAKU_DICT != ''
  ? $KENSHAKU_DICT
  : expand('~/.cache/kensaku.vim/migemo-compact-dict')
var t0 = reltime()
var dict = kdict.CompactDictionary.Load(dictPath)
out->add('load: ' .. reltimestr(reltime(t0)))

var rp = kromaji.RomajiProcessor2.Build()
t0 = reltime()
var pred = rp.RomajiToHiraganaPredictively('a')
out->add('romaji predictive(a): ' .. reltimestr(reltime(t0)) .. ' suffixes=' .. len(pred.suffixes))

t0 = reltime()
var total = 0
for suffix in pred.suffixes
  total += len(dict.PredictiveSearch(pred.prefix .. suffix))
endfor
out->add('dict search for all suffixes (' .. total .. ' hits): ' .. reltimestr(reltime(t0)))

t0 = reltime()
var gen = kternary.TernaryRegexGenerator.new('\|', '\%(', '\)', '[', ']', '', '\\.[]*~^$')
gen.Add('a')
for cand in dict.PredictiveSearch('あ')
  gen.Add(cand)
endfor
out->add('build ternary with ' .. len(dict.PredictiveSearch('あ')) .. ' candidates: ' .. reltimestr(reltime(t0)))
t0 = reltime()
var result = gen.Generate()
out->add('generate: ' .. reltimestr(reltime(t0)) .. ' len=' .. len(result))

# second run
t0 = reltime()
for i in range(3)
  var g = kternary.TernaryRegexGenerator.new('\|', '\%(', '\)', '[', ']', '', '\\.[]*~^$')
  g.Add('a')
  g.Generate()
endfor
out->add('empty-ish ternary x3: ' .. reltimestr(reltime(t0)))

writefile(out, 'tools/profile_result.txt')
qa!
