# frontend

インターン生スカウトサービスのNext.jsフロントエンドです。

リポジトリ全体の起動方法、デモアカウント、テスト手順、仕様へのリンクは、ルートの [`README.md`](../README.md) を参照してください。

## 個別コマンド

```bash
npm ci
npm run dev
npm run lint
npm run build
npm run test:e2e
```

開発時のAPIアクセスは `/api/v1` を使用し、Next.jsのrewriteで `BACKEND_INTERNAL_URL` のRails APIへ転送します。

本リポジトリでは本番公開を対象外とし、ローカルのDocker ComposeとGitHub Actionsで動作を検証します。
