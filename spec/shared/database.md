# DB設計

## users

| カラム | 型 | 制約 |
|---|---|---|
| id | bigint | PK |
| email | string | NOT NULL、前後空白除去・小文字化後UNIQUE |
| password_digest | string | NOT NULL |
| role | string | NOT NULL、student/company |
| created_at / updated_at | datetime | NOT NULL |

## student_profiles

| カラム | 型 | 制約 |
|---|---|---|
| id | bigint | PK |
| user_id | bigint | FK、NOT NULL、UNIQUE |
| last_name / first_name | string | 新規登録では必須、各50文字以内 |
| name | string | NOT NULL、姓と名を結合した互換表示値 |
| school_id | bigint | schoolsへのFK、新規登録では必須 |
| faculty_id / department_id | bigint | 各マスターへのFK、大学・大学院のみ任意 |
| school_name | string | NOT NULL、選択学校名を同期した互換表示値 |
| graduation_year | integer | NOT NULL |
| desired_role | string | NOT NULL |
| interested_roles | jsonb | NOT NULL、既定値 `[]`、新規登録では1〜3件 |
| skills | jsonb | NOT NULL、既定値 `[]` |
| self_introduction | text | NOT NULL |
| self_promotion / student_achievement / research_summary | text | NOT NULL、既定値空文字、各2,000文字以内 |
| english_skills / qualifications | text | NOT NULL、既定値空文字、各1,000文字以内 |
| visible_to_companies | boolean | NOT NULL、既定値 `true` |
| created_at / updated_at | datetime | NOT NULL |

## schools / faculties / departments

- `schools`: 学校名と `technical_college`, `vocational_school`, `junior_college`, `university`, `graduate_school` の学校種別を持つ。
- `faculties`: 学校に属する学部または研究科。学校内で名称を一意にする。
- `departments`: 学部・研究科に属する学科または専攻。親の中で名称を一意にする。
- プロフィール保存時にも各マスターの親子関係を検証する。

## company_profiles

| カラム | 型 | 制約 |
|---|---|---|
| id | bigint | PK |
| user_id | bigint | FK、NOT NULL、UNIQUE |
| company_name | string | NOT NULL、200文字以内 |
| created_at / updated_at | datetime | NOT NULL |

## conversations

| カラム | 型 | 制約 |
|---|---|---|
| id | bigint | PK |
| company_id | bigint | usersへのFK、NOT NULL |
| student_id | bigint | usersへのFK、NOT NULL |
| student_last_read_message_id | bigint | NULL可、正のメッセージID |
| created_at / updated_at | datetime | NOT NULL |

`company_id, student_id` に複合UNIQUE制約を設定し、同じ企業と学生の会話を1件に固定する。両IDが同じ値になることをCHECK制約で禁止する。
`student_last_read_message_id` は学生が受信詳細で実際に確認した最後のメッセージを表し、同じ会話内のメッセージだけを単調増加で記録する。

## messages

| カラム | 型 | 制約 |
|---|---|---|
| id | bigint | PK |
| conversation_id | bigint | FK、NOT NULL |
| sender_id | bigint | usersへのFK、NOT NULL |
| body | text | NOT NULL |
| created_at / updated_at | datetime | NOT NULL |

メッセージは `conversation_id, created_at, id` の順で古いものから安定して取得できるindexを持つ。本文は前後空白除去後1文字以上2,000文字以内とする。

## job_postings

| カラム | 型 | 制約 |
|---|---|---|
| id | bigint | PK |
| company_id | bigint | usersへのFK、NOT NULL |
| title | string | NOT NULL、120文字以内 |
| role_name | string | NOT NULL、100文字以内 |
| work_location | string | NOT NULL、200文字以内 |
| description | text | NOT NULL、5,000文字以内 |
| requirements | text | NOT NULL、3,000文字以内 |
| status | string | NOT NULL、published/closed、既定値published |
| created_at / updated_at | datetime | NOT NULL |

公開中の募集を新着順で取得するため、`status, created_at, id` に複合indexを設定する。
サムネイル画像1枚をActive Storageで関連付け、画像本体はDockerの永続ボリュームへ保存する。

## job_posting_interests

| カラム | 型 | 制約 |
|---|---|---|
| id | bigint | PK |
| student_id | bigint | usersへのFK、NOT NULL |
| job_posting_id | bigint | job_postingsへのFK、NOT NULL |
| created_at / updated_at | datetime | NOT NULL |

`student_id, job_posting_id` に複合UNIQUE制約を設定し、同じ学生と募集の重複登録を防ぐ。学生または募集が削除された場合は関連も削除する。募集終了だけでは削除しない。

## schedule_proposals

| カラム | 型 | 制約 |
|---|---|---|
| id | bigint | PK |
| conversation_id | bigint | conversationsへのFK、NOT NULL |
| starts_at / ends_at | datetime | NOT NULL、終了は開始より後 |
| location | string | NOT NULL、200文字以内 |
| note | text | NOT NULL、既定値空文字、1,000文字以内 |
| status | string | NOT NULL、pending/accepted/declined/cancelled |
| student_seen_at | datetime | NULL可、学生が提案を確認した日時 |
| created_at / updated_at | datetime | NOT NULL |

予定は `conversation_id, created_at, id` の順で安定して取得する。日時はUTCで保存し、日本時間への変換は入出力境界で行う。`student_seen_at` が未設定の回答待ち予定だけを学生向け新着通知へ含める。

## 共通制約

- 外部キーと検索対象へ適切なindexを設定する。
- `users.email` はDB制約でも大文字小文字を無視して一意にする。
- ユーザー削除時の従属データ削除方針を明示する。
- roleとプロフィール種別の整合性はモデル検証と作成サービスで保証する。
- `company_profiles` は `company` ロールのユーザーにだけ関連付ける。
- `conversations.company_id` は企業ロール、`conversations.student_id` は学生ロールだけを関連付ける。
- `messages.sender_id` は会話参加者だけを関連付ける。
- `job_postings.company_id` は企業ロールだけを関連付ける。
- `schedule_proposals` は既存会話へ関連付け、会話削除時に削除する。
- ユーザー削除時は参加する会話と送信メッセージ、会話削除時は配下のメッセージを削除する。
- 公開中の学生一覧を `created_at DESC, id DESC` で安定して取得するため、`student_profiles(visible_to_companies, created_at, id)` に複合indexを設定する。
