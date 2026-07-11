# デプロイ手順（GitHub Pages / gh-pages ブランチ）

このサイトは Astro 製の静的サイトで、`main` をビルドした成果物を
**`gh-pages` ブランチ**へ公開しています（GitHub Pages）。

- 公開ドメイン: `www.musubi-kanaderu.net`（`public/CNAME` / `astro.config.mjs` の `site`）
- 例: `public/demo/ReservedPWT.html` → `https://www.musubi-kanaderu.net/demo/ReservedPWT.html`

デプロイ手段は 2 つあり、**どちらも同じ結果**（`gh-pages` の内容）になります。

1. **Windows（従来どおり）** — ローカルの既存ワークフローで実施。
2. **Claude / Linux・macOS** — 本リポジトリの `scripts/deploy-gh-pages.sh` を実行。

---

## gh-pages ブランチの構造

`gh-pages` のブランチ直下（ルート）は次の 2 つで構成されます。

- **ソース一式**（`src/`, `public/`, `package.json`, `astro.config.mjs`, `dist/` など）
- **ビルド成果物 `dist/` の中身をルートへフラット展開したもの**
  （`index.html`, `_astro/`, `assets/`, `column/`, `news/`, `tools/`,
  `privacy-policy/`, `security-policy/`, `demo/`, `CNAME`, `.nojekyll`,
  `robots.txt`, `sitemap-*.xml` …）

GitHub Pages はこのルートの静的ファイルを配信します。`CNAME` と `.nojekyll`
はビルド時に `public/` から `dist/` へコピーされるため、ルートにも自動で載ります。

---

## Claude でのデプロイ（推奨コマンド）

```bash
./scripts/deploy-gh-pages.sh          # main をビルドして gh-pages へ公開
./scripts/deploy-gh-pages.sh main     # 明示指定（同じ）
```

スクリプトの動作:

1. `origin/main` を取得し、作業ツリーを合わせる（`git reset --hard`）
2. `npm install && npm run build`
3. `dist/` の中身をルートへ展開した内容を組み立て
4. `gh-pages` ブランチへコミット & プッシュ（差分が無ければスキップ）
5. 元の `main` に戻る

> 実行前提: 作業ツリーがクリーンであること（未コミットの変更があると中断します）。

---

## 注意点: tsconfig.json の `extends`

Windows のチェックアウトでは `tsconfig.json` の `"extends"` が
**そのマシン固有の絶対パス**になっています。

```json
"extends": "C:/apldev/nodemodules/Website/s3/node_modules/astro/tsconfigs/strict.json"
```

この絶対パスは Windows のそのマシン以外では解決できず、`astro build` が失敗します。

- `scripts/deploy-gh-pages.sh` は、この絶対パスを検出した場合のみ **ビルド時だけ**
  ポータブルな指定 `"astro/tsconfigs/strict"` に一時置換し、ビルド後に元へ戻します。
  → `main` のソースは変更されません（Windows 側の運用に影響なし）。
- 恒久対策として、`extends` を最初から `"astro/tsconfigs/strict"` にしておくと
  Windows・Linux・macOS のいずれでもそのままビルドできます（パッケージ経由で解決）。
  この置き換えは Windows でも問題なく動作します。

---

## 手動デプロイ（スクリプトを使わない場合）

```bash
# 1. main を最新化
git fetch origin main
git checkout main && git reset --hard origin/main

# 2. ビルド（tsconfig の extends が絶対パスなら一時的に "astro/tsconfigs/strict" へ）
npm install
npm run build            # dist/ に成果物が出力される（public/ の内容も含む）

# 3. gh-pages の内容を組み立て（ソース + dist/ をルートへ展開）
STAGE="$(mktemp -d)"
tar cf - --exclude=.git --exclude=node_modules . | ( cd "$STAGE" && tar xf - )
cp -a dist/. "$STAGE"/

# 4. gh-pages へ反映
git checkout -f -B gh-pages origin/gh-pages
git rm -rf . --quiet
cp -a "$STAGE"/. .
git add -A
git commit -m "ビルド成果物を更新（main を反映）"
git push origin gh-pages

# 5. 後片付け
git checkout main
```

反映は GitHub Pages 側の処理で数分ほどかかります。
