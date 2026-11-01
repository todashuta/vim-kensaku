vim9script
# Compares the character conversions against jsmigemo.
# Run from the repository root via test/run.sh.
import '../autoload/kensaku/charset.vim' as kcharset

var out: list<string> = []
for line in readfile('test/expected/charset.tsv')
  var parts = split(line, "\t", true)
  if len(parts) != 4
    continue
  endif
  var s = json_decode(parts[0])
  out->add(json_encode(s) .. "\t" .. json_encode(kcharset.Han2Zen(s)) .. "\t" .. json_encode(kcharset.Zen2Han(s)) .. "\t" .. json_encode(kcharset.Hira2Kata(s)))
endfor
writefile(out, 'test/actual/charset.tsv')
qa!
