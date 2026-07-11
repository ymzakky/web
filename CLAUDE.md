# プロジェクトメモ（Claude 向け）

キーナスデザイン株式会社のコーポレートサイト。Astro 製の静的サイト。

## 基本

- ビルド: `npm install && npm run build`（出力は `dist/`）
- 開発サーバ: `npm run dev`
- `public/` 配下はサイトルートに配信される（例: `public/demo/foo.html` → `/demo/foo.html`）
- 公開ドメイン: `www.musubi-kanaderu.net`（`public/CNAME` / `astro.config.mjs` の `site`）

## デプロイ（GitHub Pages）

`main` をビルドした成果物を **`gh-pages` ブランチ**へ公開する運用。
Windows でのローカルデプロイは従来どおり継続。Claude からデプロイする場合:

```bash
./scripts/deploy-gh-pages.sh      # main をビルドして gh-pages へ公開
```

詳細・手動手順・構造は **`docs/DEPLOY.md`** を参照。

### 注意: tsconfig.json の `extends`

Windows チェックアウトでは `tsconfig.json` の `"extends"` がそのマシン固有の
絶対パス（`C:/.../astro/tsconfigs/strict.json`）になっており、他環境では
`astro build` が失敗する。`scripts/deploy-gh-pages.sh` はビルド時だけ
ポータブルな `"astro/tsconfigs/strict"` に一時置換し、ビルド後に元へ戻す
（`main` のソースは変更しない）。手動でビルドする際も同様に対処する。
