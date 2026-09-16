# 惣菜カルテ 公開の仕組み（StatiCrypt × GitHub Pages）

## 流れ（月次）
1. 武内さん：先方から届いた月次ファイルを `Documents/プライベート/` に置き、Claudeに「〇月分」と伝える
2. Claude：`config_YYYYMM.json` を作り `python3 build_karte.py config_YYYYMM.json` → `src/index.html`（平文）を生成。必要なら `needs/<店コード>.json`（ニーズ文）を更新
3. Claude：ターミナルで `./publish.sh "〇月版"` を実行 → 暗号化 → `docs/index.html` → commit → push → 数分で反映
4. Claude：先方に更新を知らせる文面を用意（送るのは武内さん）

## 月次に要る入力（5点）
| キー | ファイル | 例（8月） |
|---|---|---|
| tanpin_csv | 全店舗全単品CSV（販売数量・金額・PI・値引・廃棄） | 26年8月全店舗全単品.csv |
| time_matrix | マトリクス分析 店舗×時間帯×単品 買上点数 | マトリクス分析_20260904145311.xlsx |
| age_matrix | マトリクス分析 店舗×年代×単品 買上金額 | マトリクス分析_20260904185727.xlsx |
| kessyutsu | 店別相乗積rank傑出リスト | 26年8月_店別相乗積rank_傑出リスト.xlsx |
| neire_book | 全単品実績xlsx（単品値入率） | （全単品実績）数式変更後26.7月累計.xlsx |
| pl_book | ブロック別業績分析xlsx（ブロック区分・人件費・経費） | 成果物/6月度_ブロック別業績分析.xlsx |

## 初回だけ（武内さんの作業・約15分）
1. staticrypt を入れる
   `npm i -g staticrypt`
2. パスワードをKeychainに保存（16字以上の文章形式。聞かれたら入力。チャットには書かない）
   `security add-generic-password -a karte -s karte-site -w`
3. GitHubで新規リポジトリ `karte-site` を作る（Public可。置くのは暗号文だけ）。READMEなど追加しない
4. このフォルダで初回push
   `git init -b main && git add . && git commit -m "初回" && git remote add origin https://github.com/<ユーザー名>/karte-site.git && git push -u origin main`
5. GitHub → Settings → Pages → Source: Deploy from a branch ／ Branch: main ／ Folder: /docs → Save
6. 数分後 `https://<ユーザー名>.github.io/karte-site/` を開き、パスワード画面が出れば完了

以降の公開は `./publish.sh` の1コマンド。Claudeがターミナル経由で実行できる（パスワードはKeychainから読むので入力不要、Claudeにも見えない）。


## 週次の更新（本部の機会損失／過剰リスト）
1. 本部から届いた「欠落_機会損失_高見廃低粗利_MMDD-MMDD.xlsx」を `data/weeks/lists_YYYY-MM-DD_YYYY-MM-DD.xlsx` の名前で置く（例 lists_2026-09-07_2026-09-13.xlsx）
2. `python3 build_yaru.py config_YYYYMM.json` → やることページの「今週の本部リスト」が更新され、先週との違い（新しく出た／続いている／解消した）と週ごとの件数が出る
3. `./publish.sh "week 9/13"` で公開
- 月次の実績（数字4つ・状態・推移・やること5つ）は月次CSVが来たときだけ変わる。ページ上部に「月次の実績：〇月〇日〜〇日」「週次の本部リスト：〇/〇〜〇/〇」を明示

## ページの使い分け
- 店長・トレーナー向け：index.html（カルテ）と yaru.html（今月やること）の両方
- パート向け：yaru.html のみ（大きな文字・5枚のカード・本部リスト・高粗利リスト）

## 先方への渡し方
- URLとパスワードは別経路（URLはメール、パスワードは口頭か電話）
- 「このブラウザで7日間記憶する」で7日は再入力なし
- パスワードを変える：Keychainの値を更新して `./publish.sh` を再実行

## ファイル
| ファイル | 役割 | Gitに入るか |
|---|---|---|
| build_karte.py | 分析→JSON→HTML生成 | 入る |
| template.html | 画面の型（`__DATA__` にJSONを差し込む） | 入る |
| needs/*.json | 店ごとのニーズ文（手で直せる） | 入る |
| config_*.json | 月ごとの入力ファイルの場所と店・お手本の指定 | 入る |
| publish.sh | 暗号化→commit→push | 入る |
| docs/index.html | 暗号化済み（公開される唯一の中身） | 入る |
| .staticrypt.json | 「記憶する」の鍵。消すと全員の記憶が切れる | 入る |
| src/index.html, data_*.json, 元データ | 平文・機密 | 入らない（.gitignore） |

## 注意
- 元データ（CSV・xlsx）と平文HTMLはリポジトリに入れない（.gitignoreで除外済み）
- 店を足すときは `config` の `stores` と `model` に追加し、`needs/<店コード>.json` を作る
- 判定の閾値（需要指数1.3／0.7、ロス差±3％／5％、粗利30％、お手本比較のロス15％）は build_karte.py の judge / compare にまとまっている
