"use client";

import Image from "next/image";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import JobInterestButton from "@/components/job-interest-button";
import { ApiRequestError, getStudentJobPostings, StudentJobPosting } from "@/lib/api";

export default function StudentJobsPage() {
  const router = useRouter();
  const [postings, setPostings] = useState<StudentJobPosting[]>([]);
  const [showInterested, setShowInterested] = useState(false);
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);

  const loadPostings = useCallback((interested: boolean) => {
    void getStudentJobPostings(interested).then(({ data }) => setPostings(data)).catch((requestError: unknown) => {
      if (requestError instanceof ApiRequestError) {
        if (requestError.errors.some((item) => item.code === "unauthenticated")) return router.replace("/students/login");
        if (requestError.errors.some((item) => item.code === "forbidden")) return router.replace("/students");
        setError(requestError.errors[0]?.message ?? "募集を読み込めませんでした。");
      } else setError("募集を読み込めませんでした。");
    }).finally(() => setIsLoading(false));
  }, [router]);

  useEffect(() => { loadPostings(false); }, [loadPostings]);

  function switchList(interested: boolean) {
    if (interested === showInterested) return;
    setShowInterested(interested);
    setIsLoading(true);
    setError("");
    loadPostings(interested);
  }

  function updateInterest(id: number, interested: boolean) {
    setPostings((current) => showInterested && !interested
      ? current.filter((posting) => posting.id !== id)
      : current.map((posting) => posting.id === id ? { ...posting, interested } : posting));
  }

  return <main className="jobs-shell">
    <Link className="back-link" href="/students/me">← 学生マイページへ戻る</Link>
    <header className="jobs-header"><div><p className="eyebrow">INTERNSHIP JOBS</p><h1>インターン募集</h1><p>企業が公開している募集を確認できます。</p></div></header>
    <div className="job-tabs" role="group" aria-label="募集の表示切り替え">
      <button type="button" className={!showInterested ? "active" : ""} aria-pressed={!showInterested} onClick={() => switchList(false)}>すべて</button>
      <button type="button" className={showInterested ? "active" : ""} aria-pressed={showInterested} onClick={() => switchList(true)}>気になる！</button>
    </div>
    {error && <div className="error-banner" role="alert">{error}</div>}
    {isLoading && <section className="list-state"><p className="loading">募集を読み込んでいます…</p></section>}
    {!isLoading && !error && postings.length === 0 && <section className="list-state empty-state"><h2>{showInterested ? "気になる募集はありません" : "公開中の募集はありません"}</h2></section>}
    {!isLoading && !error && postings.length > 0 && <section className="job-list" aria-label={showInterested ? "気になる募集" : "公開中の募集"}>{postings.map((posting) => <article className="job-card job-posting-card" key={posting.id}>
      {posting.thumbnail_url ? <Image className="job-thumbnail" src={posting.thumbnail_url} alt={`${posting.title}のサムネイル`} width={960} height={480} unoptimized /> : <div className="job-thumbnail-placeholder" aria-hidden="true">INTERNSHIP</div>}
      <div className="job-card-body"><p className="company-context">{posting.company.company_name}</p><h2>{posting.title}</h2><p className="job-role">{posting.role_name}</p><p>{posting.work_location}</p><div className="job-card-actions"><Link className="detail-link" href={`/students/jobs/${posting.id}`}>募集詳細を見る</Link><JobInterestButton id={posting.id} interested={posting.interested} onChanged={(value) => updateInterest(posting.id, value)} /></div></div>
    </article>)}</section>}
  </main>;
}
