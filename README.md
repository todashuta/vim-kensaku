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
let @/ = '\m' . kensaku#query('kensaku')
normal! n
```

`kensaku#query()` が返す正規表現には `\m` を前置していません。実際に検索に
使う前に `\m` を付けるのが簡単です（`\v` や `\m` を前置するかは呼び出し側
の都合に合わせられます）。

## 関数

| 関数 | 説明 |
| --- | --- |
| `kensaku#query({value})` | `{value}` の Migemo 正規表現を返す |
| `kensaku#search({value})` | バッファ内を検索して最初のマッチへ移動する（`:Kensaku` の実装） |
| `kensaku#reload()` | 読み込み済みの辞書を破棄する |

## 設定

| 変数 | 既定値 | 説明 |
| --- | --- | --- |
| `g:kensaku_dictionary_cache` | `~/.cache/kensaku.vim/migemo-compact-dict` | コンパクト辞書のパス |
| `g:kensaku_dictionary_url` | jsmigemo のコンパクト辞書リリース URL | 辞書の配布元（情報として保持） |

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
