vim9script
# Compares the romaji to hiragana conversion against jsmigemo.
# Run from the repository root via test/run.sh.
import '../autoload/kensaku/romaji.vim' as kromaji

var rp = kromaji.RomajiProcessor2.Build()
var out: list<string> = []
for line in readfile('test/expected/romaji.tsv')
  var parts = split(line, "\t", true)
  if len(parts) != 4
    continue
  endif
  var q = json_decode(parts[0])
  var pred = rp.RomajiToHiraganaPredictively(q)
  out->add(json_encode(q) .. "\t" .. json_encode(rp.RomajiToHiragana(q)) .. "\t" .. json_encode(pred.prefix) .. "\t" .. json_encode(join(pred.suffixes, ',')))
endfor
writefile(out, 'test/actual/romaji.tsv')
qa!
