# 実装仕様ガイド

このディレクトリを実装仕様の正本とする。Gitが変更履歴を保持するため、ファイル名には版番号を付けない。

## 要件区分

- **既定**: 課題文で定められた技術・期間・機能
- **設計判断**: 既定要件を実装可能にするため本仕様で採用した内容
- **未確定**: 実装検証または後続設計で決める内容

## 優先度

- **P0 / MVP**: 学生登録、企業ログイン、学生一覧・詳細、企業からのメッセージ送信、学生の受信確認
- **P1**: プロフィール編集・公開管理、検索・絞り込み、学生からの返信、未読管理
- **P2**: 企業の募集掲載、予定調整

## 作業別の参照ファイル

| 作業 | 最初に読むファイル | 追加で読む共通仕様 |
|---|---|---|
| 学生登録 | `features/student-registration.md` | `shared/authentication.md`, `shared/database.md`, `shared/validation.md` |
| プロフィール編集 | `features/profile-editing.md` | `shared/authorization.md`, `shared/validation.md` |
| プロフィール公開管理 | `features/profile-visibility.md` | `shared/authorization.md`, `shared/database.md` |
| 企業ログイン | `features/company-authentication.md` | `shared/authentication.md`, `shared/api-conventions.md` |
| 学生一覧 | `features/student-list.md` | `shared/authorization.md`, `shared/api-conventions.md` |
| 学生詳細 | `features/student-detail.md` | `shared/authorization.md`, `shared/database.md` |
| メッセージ | `features/messaging.md` | `shared/authorization.md`, `shared/database.md` |
| 企業の募集掲載 | `features/job-postings.md` | `shared/authorization.md`, `shared/database.md`, `shared/validation.md` |
| 面談予定の調整 | `features/scheduling.md` | `features/messaging.md`, `shared/authorization.md`, `shared/database.md` |
| 画面遷移 | `ui/user-flows.md` | `ui/screen-list.md` |
| DB変更 | 対象の機能仕様 | `shared/database.md` |
| API共通処理 | 対象の機能仕様 | `shared/api-conventions.md` |
| 認証・認可変更 | 対象の機能仕様 | `shared/authentication.md`, `shared/authorization.md` |
| 受け入れ確認 | 対象の機能仕様 | `testing/acceptance-criteria.md`, `testing/test-policy.md` |
| 判断理由の確認 | `decisions/decision-log.md` | 関連する機能・共通仕様 |

## 更新ルール

1. 機能固有の変更は `features/` に記録する。
2. 複数機能へ影響する変更は `shared/` を更新し、機能仕様から参照する。
3. 判断理由や代替案がある変更は `decisions/decision-log.md` に追記する。
4. 受け入れ条件が変わる場合は `testing/acceptance-criteria.md` も更新する。
5. `index.html` は公開用の概要であり、詳細仕様を重複させない。
