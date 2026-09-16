#!/bin/zsh
# 惣菜カルテを暗号化してGitHub Pagesに公開する（Claudeが run_in_terminal から呼ぶ／人が手で叩いてもよい）
# 使い方: ./publish.sh "9月版"      ← コミットメッセージ（省略可）
# 前提（初回だけ人が実施）:
#   npm i -g staticrypt
#   security add-generic-password -a karte -s karte-site -w   ← パスワードを1回だけ入力しKeychainに保存
#   git remote add origin https://github.com/<user>/karte-site.git
set -e
cd "$(dirname "$0")"
MSG="${1:-update $(date +%Y-%m-%d)}"
SRC="src/index.html"
[ -f "$SRC" ] || { echo "src/index.html がありません。先に build_karte.py を実行"; exit 1; }
command -v staticrypt >/dev/null || { echo "staticrypt が未インストール: npm i -g staticrypt"; exit 1; }
PW="$(security find-generic-password -a karte -s karte-site -w 2>/dev/null || true)"
[ -n "$PW" ] || { echo "Keychainにパスワードがありません: security add-generic-password -a karte -s karte-site -w"; exit 1; }
mkdir -p docs
STATICRYPT_PASSWORD="$PW" staticrypt "$SRC" -d docs --short --remember 7 \
  --template-title "惣菜カルテ" --template-instructions "パスワードを入力してください" \
  --template-button "開く" --template-placeholder "パスワード" --template-error "パスワードが違います" \
  --template-remember "このブラウザで7日間記憶する" --template-color-primary "#ED7D31" --template-color-secondary "#F7F4F0" >/dev/null
unset PW
# 平文が docs に混ざっていないか確認
grep -q "staticrypt" docs/index.html || { echo "暗号化に失敗（docs/index.htmlが平文の可能性）"; exit 1; }
git add docs .staticrypt.json README.md publish.sh .gitignore 2>/dev/null || true
if git diff --cached --quiet; then echo "変更なし"; exit 0; fi
git commit -m "$MSG" >/dev/null
git push origin main
echo "公開しました → $(git remote get-url origin | sed -E 's#https://github.com/([^/]+)/([^/.]+)(\.git)?#https://\1.github.io/\2/#')"
