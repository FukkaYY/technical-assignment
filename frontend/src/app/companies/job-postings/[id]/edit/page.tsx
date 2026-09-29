"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import JobPostingForm from "@/components/job-posting-form";
import { ApiRequestError, CompanyJobPosting, getCompanyJobPosting } from "@/lib/api";

export default function EditJobPostingPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [posting, setPosting] = useState<CompanyJobPosting | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    void getCompanyJobPosting(id).then(({ data }) => setPosting(data)).catch((requestError: unknown) => {
      if (requestError instanceof ApiRequestError) {
        if (requestError.errors.some((item) => item.code === "unauthenticated")) return router.replace("/companies/login");
        if (requestError.errors.some((item) => item.code === "forbidden")) return router.replace("/students/me");
        setError(requestError.errors[0]?.message ?? "募集を読み込めませんでした。");
      } else setError("募集を読み込めませんでした。");
    });
  }, [id, router]);

  return <main className="page-shell"><section className="form-card"><Link className="back-link" href="/companies/job-postings">← 募集管理へ戻る</Link><p className="eyebrow">EDIT JOB POSTING</p><h1>募集を編集</h1>{error && <div className="error-banner" role="alert">{error}</div>}{!posting && !error && <p className="loading">募集を読み込んでいます…</p>}{posting && <JobPostingForm id={id} initialValues={posting} initialThumbnailUrl={posting.thumbnail_url} />}</section></main>;
}
