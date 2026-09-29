"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import JobPostingForm from "@/components/job-posting-form";
import { ApiRequestError, getCurrentUser } from "@/lib/api";

export default function NewJobPostingPage() {
  const router = useRouter();
  const [isAuthorized, setIsAuthorized] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    void getCurrentUser().then(({ data }) => {
      if (data.user.role !== "company") return router.replace("/students/me");
      setIsAuthorized(true);
    }).catch((requestError: unknown) => {
      if (requestError instanceof ApiRequestError && requestError.errors.some((item) => item.code === "unauthenticated")) return router.replace("/companies/login");
      setError("認証状態を確認できませんでした。");
    });
  }, [router]);

  return <main className="page-shell"><section className="form-card"><Link className="back-link" href="/companies/job-postings">← 募集管理へ戻る</Link><p className="eyebrow">NEW JOB POSTING</p><h1>募集を作成</h1><p className="intro">保存すると学生へすぐに公開されます。</p>{error && <div className="error-banner" role="alert">{error}</div>}{!isAuthorized && !error && <p className="loading">認証状態を確認しています…</p>}{isAuthorized && <JobPostingForm />}</section></main>;
}
