"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiRequestError, getCurrentUser, login } from "@/lib/api";

export default function CompanyLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [isCheckingSession, setIsCheckingSession] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    getCurrentUser()
      .then(({ data }) => {
        if (data.user.role === "company") {
          router.replace("/students");
          return;
        }
        setIsCheckingSession(false);
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
      await login(email, password, "company");
      router.replace("/students");
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
      <section className="form-card login-card" aria-labelledby="company-login-title">
        <p className="eyebrow">COMPANY LOGIN</p>
        <h1 id="company-login-title">企業ログイン</h1>
        <p className="intro">登録済みの企業アカウントでログインしてください。</p>

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
      </section>
    </main>
  );
}
