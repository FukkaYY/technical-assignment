# 認証

## 方針

Railsが認証を管理し、暗号化・署名されたセッション情報をHttpOnly Cookieで保持する。MVPではRailsの `cookie_store` を使用する。

## 採用理由

- ブラウザJavaScriptから認証情報を読み取れない。
- Railsの標準的なセッション管理を利用できる。
- 2週間のMVPでJWTの更新・失効管理を追加せずに済む。

## Cookie

- `HttpOnly`: 必須
- `Secure`: 本番環境で必須
- `SameSite`: 配置構成に応じて `Lax` を第一候補に検証
- 有効期限: MVPでは永続期限を設けず、ブラウザーセッション終了まで
- 自動延長・永続ログイン: P0対象外

## パスワード

- Railsの `has_secure_password` を利用する。
- 平文をDB・ログ・エラーレスポンスへ残さない。
- 最低8文字。

## エンドポイント

- `GET /api/v1/csrf`
- `POST /api/v1/session`
- `DELETE /api/v1/session`
- `GET /api/v1/me`

## CSRF

- P0ではNext.jsからRailsへの同一オリジン転送を前提とする。
- Cookie認証の変更系リクエストでRailsのCSRF保護を有効にする。
- フロントエンドは `GET /api/v1/csrf` から `data.csrf_token` を取得し、変更系リクエストの `X-CSRF-Token` ヘッダーで送信する。
- `SameSite=Lax` だけをCSRF対策としない。

## ログイン

- `POST /api/v1/session` は学生・企業で共通化する。
- クライアントが送信するroleはログイン対象の絞り込みにだけ使い、保存済みユーザーのroleを変更しない。
- 成功時はセッションを再生成し、セッション固定攻撃を防ぐ。
- 資格情報とroleの不一致は、どちらが原因かを区別しない共通エラーとする。
- `POST /api/v1/session` は成否を含むすべての試行をIPアドレス単位で計数し、60秒間に5回まで許可する。6回目以降は `429 Too Many Requests` と `base` / `rate_limited` を返す。

## 未確定事項

- 本番環境でも同一オリジン転送を維持する具体的な配置方式。
