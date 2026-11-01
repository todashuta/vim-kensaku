vim9script
# Exercises the legacy rxop interface.  Run from the repository root via
# test/run.sh.
runtime! plugin/*.vim

var errors: list<string> = []

# The default rxop prepends \m.  This is what makes integration plugins such
# as kensaku-command.vim work: they build '\v' .. kensaku#query(value) and the
# \m overrides their \v.
var pattern = kensaku#query('kensaku')
if strpart(pattern, 0, 2) !=# '\m'
  errors->add('default query does not start with \m: ' .. strpart(pattern, 0, 10))
endif

# g:kensaku#rxop#javascript has no prefix and uses the JavaScript operators.
var js = kensaku#query('kensaku', {'rxop': g:kensaku#rxop#javascript})
if strpart(js, 0, 2) ==# '\m'
  errors->add('javascript rxop should not have a prefix')
endif
if js !~# '|' || js !~# '(?:'
  errors->add('javascript rxop was not applied: ' .. strpart(js, 0, 20))
endif

# The legacy list form [prefix, or, startGroup, endGroup, startClass,
# endClass, newline] is still accepted.
var legacy = kensaku#query('kensaku', {
  rxop: ['\m', '\|', '\%(', '\)', '[', ']', ''],
})
if strpart(legacy, 0, 2) !=# '\m'
  errors->add('legacy list rxop was not applied: ' .. strpart(legacy, 0, 10))
endif

# The legacy list form without a prefix is accepted too.
var legacyNoPrefix = kensaku#query('kensaku', {
  rxop: ['\|', '\%(', '\)', '[', ']', ''],
})
if strpart(legacyNoPrefix, 0, 2) ==# '\m'
  errors->add('legacy list rxop without prefix should not have one')
endif

# kensaku-command.vim style: '\v' .. kensaku#query(value) must still be a
# valid regexp and must match Japanese.
try
  var vpattern = '\v' .. kensaku#query('kensaku')
  if match('けんさく', vpattern) < 0
    errors->add('kensaku-command style pattern does not match')
  endif
catch
  errors->add('kensaku-command style pattern raised: ' .. v:exception)
endtry

writefile(empty(errors) ? ['ok'] : errors, 'test/actual/rxop.txt')
qa!
