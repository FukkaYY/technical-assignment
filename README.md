# technical-assignment

企業と学生をつなぐインターンスカウトサービスの技術課題リポジトリです。

企業による学生検索・スカウトから、学生の返信、面談調整、インターン募集の掲載までを一つのサービスで試せます。本番公開は行わず、Docker Composeでのローカル再現とGitHub Actionsによる自動検証を提出範囲としています。

## 最短で起動する

### 必要なもの

- Docker Desktop（Docker Compose v2を含む）
- Git

Docker Desktopを起動し、リポジトリ直下で以下を実行します。

PowerShell:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
docker compose up --build -d
docker compose exec backend bin/rails db:seed
```

macOS / Linux / Git Bash:

```bash
[ -f .env ] || cp .env.example .env
docker compose up --build -d
docker compose exec backend bin/rails db:seed
```

起動後、ブラウザで <http://localhost:3000> を開きます。初回はイメージのビルドと依存関係の取得に時間がかかる場合があります。

| 確認先 | URL |
|---|---|
| アプリ | <http://localhost:3000> |
| APIヘルスチェック（Next.js経由） | <http://localhost:3000/api/v1/health> |
| Rails API直接アクセス | <http://localhost:3001/api/v1/health> |

ログの確認と停止には次を使用します。

```powershell
docker compose logs -f
docker compose down
```

DBデータとアップロード画像も初期化したい場合に限り、`docker compose down --volumes`を実行してください。

## デモアカウント

| ロール | メールアドレス | パスワード |
|---|---|---|
| 企業 | `company@example.com` | `password123` |
| 学生 | `student01@example.com` | `password123` |

企業アカウントは「企業の方はこちら」、学生アカウントは「学生の方はこちら」からログインします。seedは再実行可能で、企業、学生、学校マスターなどのデモデータを用意します。

## おすすめの確認フロー

1. 企業としてログインし、学校・卒業予定年・興味のある職種で学生を絞り込む。
2. 学生詳細からスカウトメッセージと面談予定を送る。
3. ログアウトし、対象の学生アカウントでログインする。
4. マイページの未読メッセージ・新しい面談提案の通知を確認する。
5. 会話詳細で返信し、面談を承諾または辞退する。
6. 企業へ戻り、メッセージ一覧と面談状態へ反映されたことを確認する。

募集掲載を試す場合は、企業の「募集を管理」からサムネイル付き募集を作成し、学生の「インターン募集を見る」から「気になる！」への登録・絞り込みを確認できます。

## 主な機能

### 学生向け

- 姓・名を分けた学生登録
- 学校種別、学校、学部・研究科、学科・専攻のマスター選択
- 最大3件の「興味のある職種」と、観点別に分けたプロフィール編集
- 企業へのプロフィール公開・非公開の切り替え
- 企業との1対1メッセージ、返信、会話履歴
- 未読メッセージと新しい面談提案を分けた赤色通知
- 面談予定の承諾・辞退
- 公開中のインターン募集の閲覧と「気になる！」管理

### 企業向け

- 学校種別、学校、卒業予定年、興味のある職種による学生の絞り込み
- 公開中の学生プロフィール詳細の確認
- 学生へのスカウト送信と、学生単位のメッセージ一覧
- 15分刻みの開始日時と所要時間による面談提案・取消
- サムネイル付きインターン募集の作成・編集・募集終了

## アピールポイント

### 1. スカウト後のやり取りまで完結する

学生を探してメッセージを送るだけでなく、学生からの返信、未読管理、面談提案への回答まで実装しています。企業と学生の組み合わせごとに会話を一つにまとめ、過去の経緯を追いやすくしました。

### 2. 学生が迷いにくい入力設計

学校名や所属を自由入力ではなく連動するローカルマスターから選択させ、表記揺れや存在しない学校名を防ぎます。「希望職種」ではなく最大3件の「興味のある職種」とし、進路を決め切っていない学生も登録できます。

### 3. プライバシーと認可をAPI側で保証する

学生はプロフィールを企業から非公開にできます。一方で、非公開後も既に始まった会話と面談調整は継続できます。画面の表示制御だけに頼らず、Rails側でロール、所有者、会話参加者を検証し、他社・他学生の非公開リソースは404として存在も隠します。

### 4. Cookie認証を前提にした基本的な防御

RailsのセッションとHttpOnly Cookieを使用し、変更系APIをCSRFトークンで保護しています。ログインAPIには試行回数制限を設け、企業向け学生APIからログイン用メールアドレスを除外しています。

### 5. 要件と判断理由を追跡できる

機能別仕様、共通仕様、画面遷移、受け入れ条件を`spec/`へ分割し、独自に決めた内容と理由をDecision Logへ残しています。公開概要の`index.html`、README、実装仕様、テストを同じ変更単位で更新する運用にしています。

### 6. 主要フローを三層で検証する

GitHub Actionsで以下を独立して実行します。

- frontend: ESLint、TypeScriptを含むNext.js本番ビルド
- backend: PostgreSQLを使ったRails model/request spec
- E2E: Docker Compose上でのPlaywrightテスト

E2Eでは、企業ログイン、学生検索、スカウト、面談提案、学生通知・返信・承諾、企業側への反映に加え、募集作成と「気になる！」までをブラウザ操作で確認します。失敗時はログ、スクリーンショット、動画、traceをGitHub Actionsのartifactとして保存します。

## 技術構成

- Ruby 3.4.10 / Rails 8.1.3.1（APIモード）
- Node.js 24 LTS / Next.js 16.3.3 / TypeScript
- PostgreSQL 17
- Docker Compose
- RSpec / Playwright / GitHub Actions

Next.jsから`/api/v1`へのリクエストをRailsへ転送する同一サイト構成とし、フロントエンドから接続先の違いを意識せずAPIを利用できるようにしています。

## テスト

Docker Composeでバックエンドテストを実行する場合:

```powershell
docker compose run --rm -e RAILS_ENV=test -e DATABASE_URL=postgresql://postgres:postgres@db:5432/technical_assignment_test backend sh -c "bin/rails db:prepare && bundle exec rspec"
```

フロントエンドの静的検証:

```powershell
Set-Location frontend
npm ci
npm run lint
npm run build
```

Playwright E2Eは、アプリを起動してseedを投入した状態で実行します。初回のみChromiumをインストールしてください。

```powershell
Set-Location frontend
npx playwright install chromium
npm run test:e2e
```

失敗時のスクリーンショット、動画、traceは`frontend/test-results/`に保存されます。

## Dockerを使わない起動

Ruby 3.4.10、PostgreSQL 17、Node.js 24を用意します。まずバックエンドを起動します。

```powershell
Set-Location backend
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails server -p 3001
```

別のPowerShellでフロントエンドを起動します。

```powershell
Set-Location frontend
npm ci
$env:BACKEND_INTERNAL_URL = "http://localhost:3001"
npm run dev
```

## ディレクトリ構成

```text
backend/       Rails API、model/request spec
frontend/      Next.js UI、Playwright E2E
spec/          機能仕様、共通仕様、画面、受け入れ条件、Decision Log
compose.yaml   ローカル実行環境
index.html     公開用の仕様概要
```

## 仕様の参照先

- 実装用の仕様入口: [`spec/README.md`](spec/README.md)
- 機能別仕様: [`spec/features/`](spec/features/)
- 共通仕様: [`spec/shared/`](spec/shared/)
- 画面とフロー: [`spec/ui/`](spec/ui/)
- テスト仕様: [`spec/testing/`](spec/testing/)
- 設計判断: [`spec/decisions/decision-log.md`](spec/decisions/decision-log.md)
- 公開用の概要: [`index.html`](index.html)

## 環境変数と公開時の注意

`.env.example`の値はローカル開発専用のダミーです。`.env`はコミットしません。デモ企業の資格情報は`DEMO_COMPANY_EMAIL`と`DEMO_COMPANY_PASSWORD`で変更できます。

現在は本番公開していません。将来公開する場合は、配置方式、HTTPS、Cookie、CORS、CSRF、秘密情報、DB migration、ログ、バックアップとロールバックを改めて設計・検証する必要があります。
