"use client";

import { FormEvent, useEffect, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { ApiRequestError, getCurrentUser, login } from "@/lib/api";

export default function StudentLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isCheckingSession, setIsCheckingSession] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    getCurrentUser()
      .then(({ data }) => {
        router.replace(data.user.role === "student" ? "/students/me" : "/students");
      })
      .catch((requestError: unknown) => {
        if (!(requestError instanceof ApiRequestError) || !requestError.errors.some((item) => item.code === "unauthenticated")) {
          setError("ログイン状態の確認に失敗しました。");
        }
        setIsCheckingSession(false);
      });
  }, [router]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      await login(email, password, "student");
      router.replace("/students/me");
    } catch (requestError) {
      if (requestError instanceof ApiRequestError) {
        setError(requestError.errors[0]?.message ?? "ログインに失敗しました。");
      } else {
        setError("通信に失敗しました。時間をおいて再度お試しください。");
      }
      setIsSubmitting(false);
    }
  }

  return (
    <main className="page-shell">
      <section className="form-card login-card" aria-labelledby="student-login-title">
        <p className="eyebrow">STUDENT LOGIN</p>
        <h1 id="student-login-title">学生ログイン</h1>
        <p className="intro">登録済みの学生アカウントでログインしてください。</p>

        {error && <div className="error-banner" role="alert">{error}</div>}

        {isCheckingSession ? (
          <p className="loading">ログイン状態を確認しています…</p>
        ) : (
          <form onSubmit={handleSubmit}>
            <div className="form-grid single-column">
              <div className="field field-wide">
                <label htmlFor="email">メールアドレス <span className="required-label">必須</span></label>
                <input id="email" type="email" value={email} onChange={(event) => setEmail(event.target.value)} autoComplete="email" required />
              </div>
              <div className="field field-wide">
                <label htmlFor="password">パスワード <span className="required-label">必須</span></label>
                <input id="password" type="password" value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="current-password" required />
              </div>
            </div>
            <button className="primary-button full-width" type="submit" disabled={isSubmitting}>
              {isSubmitting ? "ログイン中…" : "ログイン"}
            </button>
          </form>
        )}

        <p className="login-alternative">アカウントをお持ちでない方は <Link href="/students/register">学生登録</Link></p>
      </section>
    </main>
  );
}
