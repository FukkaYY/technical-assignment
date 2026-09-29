"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiRequestError, getConversations, getCurrentUser, logout, StudentProfile, updateStudentProfileVisibility } from "@/lib/api";

export default function StudentMyPage() {
  const router = useRouter();
  const [profile, setProfile] = useState<StudentProfile | null>(null);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [unreadCount, setUnreadCount] = useState<number | null>(null);
  const [unseenProposalCount, setUnseenProposalCount] = useState<number | null>(null);
  const [unreadError, setUnreadError] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [isUpdatingVisibility, setIsUpdatingVisibility] = useState(false);

  useEffect(() => {
    let cancelled = false;

    getCurrentUser()
      .then(({ data }) => {
        if (cancelled) return;
        if (data.user.role !== "student") {
          router.replace("/students");
          return;
        }
        if (!data.student_profile) {
          setError("学生プロフィールを表示できません。");
          return;
        }
        setProfile(data.student_profile);
        void getConversations()
          .then(({ data: conversations }) => {
            if (!cancelled) {
              setUnreadCount(conversations.reduce((total, conversation) => total + conversation.unread_count, 0));
              setUnseenProposalCount(conversations.reduce((total, conversation) => total + conversation.unseen_schedule_proposal_count, 0));
            }
          })
          .catch(() => {
            if (!cancelled) setUnreadError(true);
          });
        if (new URLSearchParams(window.location.search).get("updated") === "1") {
          setNotice("プロフィールを更新しました。");
          window.history.replaceState(null, "", "/students/me");
        }
      })
      .catch((requestError: unknown) => {
        if (cancelled) return;
        if (requestError instanceof ApiRequestError && requestError.errors.some((item) => item.code === "unauthenticated")) {
          router.replace("/students/login");
          return;
        }
        setError("プロフィールの読み込みに失敗しました。");
      });

    return () => {
      cancelled = true;
    };
  }, [router]);

  async function handleLogout() {
    setIsLoggingOut(true);
    setError("");
    try {
      await logout();
      router.replace("/");
    } catch {
      setError("ログアウトに失敗しました。");
      setIsLoggingOut(false);
    }
  }

  async function handleVisibilityChange() {
    if (!profile) return;

    const nextVisibility = !profile.visible_to_companies;
    setError("");
    setNotice("");
    setIsUpdatingVisibility(true);
    try {
      const response = await updateStudentProfileVisibility(nextVisibility);
      setProfile(response.data);
      setNotice(nextVisibility ? "プロフィールを企業へ公開しました。" : "プロフィールを企業から非公開にしました。");
    } catch (requestError) {
      setError(requestError instanceof ApiRequestError ? requestError.errors[0]?.message ?? "公開状態の変更に失敗しました。" : "公開状態の変更に失敗しました。");
    } finally {
      setIsUpdatingVisibility(false);
    }
  }

  return (
    <main className="page-shell">
      <section className="profile-card" aria-live="polite">
        {error && <div className="error-banner" role="alert">{error}</div>}
        {notice && <div className="success-banner" role="status">{notice}</div>}

        {!profile && !error && <p className="loading">プロフィールを読み込んでいます…</p>}

        {profile && (
          <>
            <header className="student-mypage-header">
              <div>
                <p className="eyebrow">STUDENT MY PAGE</p>
                <h1>{profile.name}さん</h1>
                <p className="intro">登録プロフィールと企業から届いたメッセージを確認できます。</p>
              </div>
              <button className="danger-button" type="button" onClick={handleLogout} disabled={isLoggingOut}>
                {isLoggingOut ? "ログアウト中…" : "ログアウト"}
              </button>
            </header>
            {unreadCount !== null && unreadCount > 0 && (
              <div className="unread-notification" role="status">
                企業から未読メッセージが<strong>{unreadCount}件</strong>届いています。
              </div>
            )}
            {unseenProposalCount !== null && unseenProposalCount > 0 && (
              <div className="unread-notification" role="status">
                新しい面談提案が<strong>{unseenProposalCount}件</strong>あります。
              </div>
            )}
            {unreadError && <p className="unread-status-error">未読状況を取得できませんでした。</p>}
            <nav className="student-mypage-navigation" aria-label="学生マイページのメニュー">
              <Link className="primary-link mypage-inbox-link" href="/students/messages">
                受信メッセージを見る
                {unreadCount !== null && unreadCount > 0 && <span className="mypage-unread-badge">未読 {unreadCount}件</span>}
                {unseenProposalCount !== null && unseenProposalCount > 0 && <span className="mypage-unread-badge">面談提案 {unseenProposalCount}件</span>}
              </Link>
              <Link className="secondary-link" href="/students/jobs">インターン募集を見る</Link>
              <Link className="secondary-link" href="/students/me/edit">プロフィールを編集</Link>
            </nav>
            <dl className="profile-summary">
              <div><dt>学校名</dt><dd>{profile.school_name}</dd></div>
              {profile.faculty_name && <div><dt>{profile.school_type === "graduate_school" ? "研究科" : "学部"}</dt><dd>{profile.faculty_name}</dd></div>}
              {profile.department_name && <div><dt>学科・専攻</dt><dd>{profile.department_name}</dd></div>}
              <div><dt>卒業予定</dt><dd>{profile.graduation_year}年</dd></div>
              <div><dt>興味のある職種</dt><dd>{profile.interested_roles.length > 0 ? profile.interested_roles.join(" / ") : profile.desired_role}</dd></div>
            </dl>
            {![profile.self_promotion, profile.student_achievement, profile.research_summary, profile.english_skills, profile.qualifications].some(Boolean) && <div className="notice-banner" role="status">アピール情報が未登録です。プロフィール編集から追加すると、企業に経験や関心を伝えられます。</div>}
            <section className="profile-visibility" aria-labelledby="profile-visibility-heading">
              <div>
                <h2 id="profile-visibility-heading">企業への公開状態</h2>
                <p className={profile.visible_to_companies ? "visibility-status visible" : "visibility-status private"}>
                  {profile.visible_to_companies ? "公開中" : "非公開"}
                </p>
                <p>{profile.visible_to_companies ? "企業の学生一覧と検索結果にプロフィールが表示されます。" : "企業の学生一覧・検索結果・学生詳細には表示されません。既存の会話は引き続き利用できます。"}</p>
              </div>
              <button className="secondary-button compact-button" type="button" onClick={handleVisibilityChange} disabled={isUpdatingVisibility}>
                {isUpdatingVisibility ? "変更中…" : profile.visible_to_companies ? "プロフィールを非公開にする" : "プロフィールを公開する"}
              </button>
            </section>
          </>
        )}
      </section>
    </main>
  );
}
