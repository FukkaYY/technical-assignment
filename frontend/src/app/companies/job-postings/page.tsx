"use client";

import Link from "next/link";
import Image from "next/image";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiRequestError, closeCompanyJobPosting, CompanyJobPosting, getCompanyJobPostings } from "@/lib/api";

export default function CompanyJobPostingsPage() {
  const router = useRouter();
  const [postings, setPostings] = useState<CompanyJobPosting[]>([]);
  const [error, setError] = useState("");
  const [notice, setNotice] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [closingId, setClosingId] = useState<number | null>(null);

  useEffect(() => {
    const saved = new URLSearchParams(window.location.search).get("saved");
    if (saved) {
      window.history.replaceState(null, "", "/companies/job-postings");
    }
    void getCompanyJobPostings()
      .then(({ data }) => {
        setPostings(data);
        if (saved) setNotice(saved === "created" ? "募集を公開しました。" : "募集を更新しました。");
      })
      .catch((requestError: unknown) => handleError(requestError, router, setError))
      .finally(() => setIsLoading(false));
  }, [router]);

  async function closePosting(id: number) {
    setClosingId(id);
    setError("");
    try {
      const { data } = await closeCompanyJobPosting(id);
      setPostings((current) => current.map((posting) => posting.id === id ? data : posting));
      setNotice("募集を終了しました。");
    } catch (requestError: unknown) {
      handleError(requestError, router, setError);
    } finally {
      setClosingId(null);
    }
  }

  return (
    <main className="jobs-shell">
      <Link className="back-link" href="/students">← 学生一覧へ戻る</Link>
      <header className="jobs-header">
        <div><p className="eyebrow">JOB POSTINGS</p><h1>募集管理</h1><p>自社のインターン募集を作成・編集できます。</p></div>
        <Link className="primary-link" href="/companies/job-postings/new">新しい募集を作成</Link>
      </header>
      {notice && <div className="success-banner" role="status">{notice}</div>}
      {error && <div className="error-banner" role="alert">{error}</div>}
      {isLoading && <section className="list-state"><p className="loading">募集を読み込んでいます…</p></section>}
      {!isLoading && !error && postings.length === 0 && <section className="list-state empty-state"><h2>募集はまだありません</h2><p>最初の募集を作成してください。</p></section>}
      {!isLoading && postings.length > 0 && (
        <section className="job-list" aria-label="自社の募集">
          {postings.map((posting) => (
            <article className="job-card job-posting-card" key={posting.id}>
              {posting.thumbnail_url ? <Image className="job-thumbnail" src={posting.thumbnail_url} alt={`${posting.title}のサムネイル`} width={960} height={480} unoptimized /> : <div className="job-thumbnail-placeholder" aria-hidden="true">INTERNSHIP</div>}
              <div className="job-card-body">
              <div className="job-card-heading"><div><span className={`status-badge ${posting.status}`}>{posting.status === "published" ? "公開中" : "募集終了"}</span><h2>{posting.title}</h2></div><time dateTime={posting.created_at}>{formatDate(posting.created_at)}</time></div>
              <p className="job-role">{posting.role_name}</p><p>{posting.work_location}</p>
              <div className="actions"><Link className="secondary-link" href={`/companies/job-postings/${posting.id}/edit`}>編集する</Link>{posting.status === "published" && <button className="secondary-button" type="button" onClick={() => closePosting(posting.id)} disabled={closingId === posting.id}>{closingId === posting.id ? "終了処理中…" : "募集を終了"}</button>}</div>
              </div>
            </article>
          ))}
        </section>
      )}
    </main>
  );
}

function handleError(error: unknown, router: ReturnType<typeof useRouter>, setError: (message: string) => void) {
  if (error instanceof ApiRequestError) {
    if (error.errors.some((item) => item.code === "unauthenticated")) return router.replace("/companies/login");
    if (error.errors.some((item) => item.code === "forbidden")) return router.replace("/students/me");
    setError(error.errors[0]?.message ?? "募集の読み込みに失敗しました。");
  } else setError("募集の読み込みに失敗しました。");
}

function formatDate(value: string) { return new Intl.DateTimeFormat("ja-JP", { dateStyle: "medium" }).format(new Date(value)); }
