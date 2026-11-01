vim9script
# Exercises the :Kensaku command.
runtime! plugin/*.vim

var errors: list<string> = []
setline(1, ['はじめの行', 'ここに検索したい語があるよ', 'おわりの行'])
Kensaku kensaku
if getline('.') !=# 'ここに検索したい語があるよ'
  errors->add('cursor moved to: ' .. getline('.'))
endif
if empty(@/)
  errors->add('search register is empty')
endif

# A query that has no candidates must not change the cursor.
cursor(1, 1)
Kensaku zzzz
if getline('.') !=# 'はじめの行'
  errors->add('cursor moved for a non-matching query')
endif
writefile(empty(errors) ? ['ok'] : errors, 'test/actual/search.txt')
qa!
