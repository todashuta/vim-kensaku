# kensaku.vim (Vim9 script)

[![Vim 9.2 or above](https://img.shields.io/badge/Vim-9.2%20or%20above-yellowgreen.svg?logo=vim)](https://github.com/vim/vim)

ローマ字のまま日本語を検索する [Migemo][migemo] プラグインを、**Vim9 script
だけで**実装したものです。[lambdalisue/vim-kensaku][vim-kensaku] は
Deno + [denops.vim][denops] + [jsmigemo][jsmigemo] で動いていますが、この
プラグインは Vim 本体以外に何も必要としません。

[migemo]: http://0xcc.net/migemo/
[vim-kensaku]: https://github.com/lambdalisue/vim-kensaku
[denops]: https://github.com/vim-denops/denops.vim
[jsmigemo]: https://github.com/oguna/jsmigemo

```
"kensaku"  =>  \%(kensaku\|けんさく\|ケンサク\|建策\|憲[作冊]\|検索\|献策\|研削\|羂索\|...\)
```

## 必要条件

- Vim 9.2 以降（`:import` の名前空間形式と Vim9 クラスを使用）
- Migemo コンパクト辞書（約 2.1MB）

Neovim は対象外です（Vim9 script のクラスと `:import` に依存しています）。

## セットアップ

辞書をダウンロードします。

```sh
mkdir -p ~/.cache/kensaku.vim
curl -fL -o ~/.cache/kensaku.vim/migemo-compact-dict \
  https://github.com/oguna/migemo-compact-dict-latest/releases/download/v0.2/migemo-compact-dict
```

あとはお好みのプラグインマネージャーでインストールしてください。辞書は最初の
クエリ時に遅延ロードされるので、Vim の起動は遅くなりません。

```vim
Plug 'todashuta/vim-kensaku'
```

## 使い方

```vim
:Kensaku kensaku
```

バッファ内を Migemo 正規表現で検索し、最初のマッチへ移動します。

Vim script から使う場合:

```vim
let @/ = kensaku#query('kensaku')
normal! n
```

`kensaku#query()` はデフォルトで `\m` を前置した正規表現を返します。`\v` を
前置する [lambdalisue/kensaku-command.vim][kensaku-command] のような
インテグレーションプラグインと組み合わせても、`\v` の後に `\m` が来るため
magic モードで解釈され、そのまま動きます。

[kensaku-command]: https://github.com/lambdalisue/vim-kensaku-command

このプラグインも `:Kensaku` コマンドを提供します。kensaku-command.vim と併用
する場合、`:Kensaku` は後に読み込まれたプラグインの定義が使われます。

## 関数

| 関数 | 説明 |
| --- | --- |
| `kensaku#query({value}[, {option}])` | `{value}` の Migemo 正規表現を返す |
| `kensaku#query_async({value}, {success}[, {option}])` | 結果を `{success}` に渡す（実装は同期） |
| `kensaku#search({value})` | バッファ内を検索して最初のマッチへ移動する（`:Kensaku` の実装） |
| `kensaku#reload()` | 読み込み済みの辞書を破棄する |

`{option}` には `"rxop"` を指定できます。rxop は正規表現に使う記号を定義する
辞書で、`prefix` / `or` / `startGroup` / `endGroup` / `startClass` /
`endClass` / `newline` / `escape` を持ちます。旧形式のリスト
`[prefix, or, startGroup, endGroup, startClass, endClass, newline]` と
`[or, startGroup, endGroup, startClass, endClass, newline]` も受け付けます。

`kensaku#set_roman_table()`（azik などのローマ字テーブル差し替え）はこの実装
では未対応です。

## 設定

| 変数 | 既定値 | 説明 |
| --- | --- | --- |
| `g:kensaku_dictionary_cache` | `~/.cache/kensaku.vim/migemo-compact-dict` | コンパクト辞書のパス |
| `g:kensaku_dictionary_url` | jsmigemo のコンパクト辞書リリース URL | 辞書の配布元（情報として保持） |
| `g:kensaku#rxop#vim` | `\m` 前置の Vim 用 rxop | `kensaku#query()` の既定値 |
| `g:kensaku#rxop#javascript` | プレフィックスなしの JavaScript 用 rxop | 他言語向けの正規表現を作るとき用 |

## 実装

jsmigemo の各クラスを Vim9 script に移植しています。

```
autoload/kensaku/bitvector.vim   BitVector (rank/select)
autoload/kensaku/loudstrie.vim   LOUDSTrie
autoload/kensaku/dictionary.vim  CompactDictionary
autoload/kensaku/doublearray.vim DoubleArray
autoload/kensaku/romaji.vim      RomajiProcessor2
autoload/kensaku/charset.vim     全角半角・ひらがなカタカナ変換
autoload/kensaku/ternary.vim     TernaryRegexGenerator
autoload/kensaku/migemo.vim      Migemo
```

移植で変わった点:

- jsmigemo の generator は Vim9 script にないため、候補をリストに集めて返す
- jsmigemo の null 許容の木構造は、Vim9 script に null がないため、1 本の
  数値リストと「インデックス 0 = ノードなし」で表現する
- 記号のビット演算子がないため `and()` / `or()` / `invert()` を使う
- ローマ字変換・文字変換のテーブルは jsmigemo のソースから
  `tools/generate-tables.py` で生成する

## テスト

jsmigemo の出力を期待値として、次の 3 点を突き合わせています。

- 20 のクエリで jsmigemo が生成する正規表現と完全一致するか
- jsmigemo の `test/romantable.txt` の 322 入力でローマ字からひらがなへの
  変換と予測変換が一致するか（期待値は `test/expected/romaji.tsv`）
- 全角半角・ひらがなカタカナ変換が一致するか

辞書はリポジトリに含めていないので、パスを指定して実行します。

```sh
KENSHAKU_DICT=~/.cache/kensaku.vim/migemo-compact-dict ./test/run.sh
```

期待値は jsmigemo 0.4.8 と上のセットアップでダウンロードする v0.2 の辞書で生成
しています。辞書が変わると生成される正規表現も変わるため、同じ辞書を使ってくだ
さい。

## 性能

手元の環境（Vim 9.2、辞書 2.1MB）での実測値です。

| 場面 | 時間 |
| --- | --- |
| 初回クエリ（辞書ロード込み） | 約 0.75 秒 |
| 定常状態のクエリ | 11〜25ms |
| 1 文字クエリ `a`（候補 3597 件） | 約 1.8 秒 |

辞書は最初のクエリまで読み込まれません。1 文字クエリは候補が膨大になるため
遅くなりますが、インクリメンタル検索でも 2 文字目以降は実用的な速度になります。

## ライセンス

MIT License。詳細は [LICENSE](./LICENSE) を参照してください。

このリポジトリは [lambdalisue/vim-kensaku][vim-kensaku] を Vim9 script で
実装し直したもので、[jsmigemo][jsmigemo] の各クラスを移植しています。どちらも
MIT License です。
