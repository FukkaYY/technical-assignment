# システム構成

## 採用方針

| 領域 | 方針 | 区分 |
|---|---|---|
| リポジトリ | GitHubモノレポ | 設計判断 |
| フロントエンド | Next.js App Router + TypeScript | 既定＋詳細判断 |
| バックエンド | Rails APIモード、JSON REST API | 既定＋詳細判断 |
| DB | PostgreSQL | 設計判断 |
| 認証 | Railsセッション + HttpOnly Cookie | 設計判断 |
| 開発環境 | Docker Compose | 設計判断 |
| CI | GitHub Actions | 設計判断 |
| 本番公開 | 対象外。Docker ComposeとCIで再現・検証する | 設計判断 |

## 固定バージョン

| 対象 | バージョン |
|---|---|
| Ruby | 3.4.10 |
| Rails | 8.1.3.1 |
| Node.js | 24 LTS |
| Next.js | 16.3.3 |
| PostgreSQL | 17 |

パッチ更新はセキュリティ修正を優先し、依存関係更新時はCIでフロントエンドのlint・buildとRailsのrequest specを確認する。

## ディレクトリ案

```text
repository/
├── backend/          # Rails API
├── frontend/         # Next.js
├── spec/             # 実装仕様
├── compose.yaml
├── index.html        # 公開用仕様概要
└── README.md
```

## 通信

- Next.jsから `/api` へアクセスし、ローカルとE2Eでは同一サイトとしてRailsへ転送する。
- 本番公開は本課題の対象外とする。将来公開する場合は、同一オリジン構成、Cookie、CORS、CSRF、秘密情報、DB移行を改めて設計・検証する。
- APIは `/api/v1` 配下へ置く。

## 2週間の実装順

1. モノレポ、Rails、Next.js、PostgreSQL、Docker、CI
2. 学生登録とセッション認証
3. 企業seed、企業ログイン、認可
4. 学生一覧・詳細
5. メッセージ送信・受信
6. テスト、UI調整、README
7. 余裕があればP1

P0実装完了後はPlaywrightで企業送信から学生受信までを通し、GitHub Actionsの独立したE2Eジョブで継続検証する。
