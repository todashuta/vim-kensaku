vim9script
var out: list<string> = []

var t0 = reltime()
kensaku#query('kensaku')
out->add('cold (load + first query): ' .. reltimestr(reltime(t0)))

t0 = reltime()
var queries = ['kensaku', 'nihon', 'tokyo', 'kaguya', 'migemo', 'kanji', 'tsukuyomi', 'arugorizumu', 'sakura', 'yamato']
for i in range(10)
  for q in queries
    kensaku#query(q)
  endfor
endfor
out->add('100 warm queries: ' .. reltimestr(reltime(t0)))

t0 = reltime()
for i in range(100)
  kensaku#query('kensaku')
endfor
out->add('100 identical queries: ' .. reltimestr(reltime(t0)))

t0 = reltime()
var p = kensaku#query('a')
out->add('query(a) len=' .. len(p) .. ': ' .. reltimestr(reltime(t0)))

t0 = reltime()
p = kensaku#query('kaguyakaguyakaguya')
out->add('query(long): ' .. reltimestr(reltime(t0)))

# total process memory (Linux)
out->add('mem: ' .. trim(system('grep VmRSS /proc/' .. getpid() .. '/status')))

writefile(out, 'tools/bench_result.txt')
qa!
