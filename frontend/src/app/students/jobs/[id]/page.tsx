"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import JobInterestButton from "@/components/job-interest-button";
import { ApiRequestError, getStudentJobPosting, StudentJobPosting } from "@/lib/api";

export default function StudentJobDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [posting, setPosting] = useState<StudentJobPosting | null>(null);
  const [error, setError] = useState("");
  useEffect(() => { void getStudentJobPosting(id).then(({ data }) => setPosting(data)).catch((requestError: unknown) => {
    if (requestError instanceof ApiRequestError) {
      if (requestError.errors.some((item) => item.code === "unauthenticated")) return router.replace("/students/login");
      if (requestError.errors.some((item) => item.code === "forbidden")) return router.replace("/students");
      setError(requestError.errors[0]?.message ?? "募集を表示できませんでした。");
    } else setError("募集を表示できませんでした。");
  }); }, [id, router]);
  return <main className="jobs-shell"><Link className="back-link" href="/students/jobs">← 募集一覧へ戻る</Link>{error && <section className="list-state error-state" role="alert"><h1>募集を表示できません</h1><p>{error}</p></section>}{!posting && !error && <section className="list-state"><p className="loading">募集を読み込んでいます…</p></section>}{posting && <article className="job-detail">
    {posting.thumbnail_url ? <Image className="job-detail-thumbnail" src={posting.thumbnail_url} alt={`${posting.title}のサムネイル`} width={1200} height={600} unoptimized /> : <div className="job-detail-thumbnail job-thumbnail-placeholder" aria-hidden="true">INTERNSHIP</div>}
    <div className="job-detail-heading"><div><p className="eyebrow">INTERNSHIP JOB</p><p className="company-context">{posting.company.company_name}</p><h1>{posting.title}</h1></div><JobInterestButton id={posting.id} interested={posting.interested} onChanged={(interested) => setPosting((current) => current ? { ...current, interested } : current)} /></div>
    <dl className="job-detail-meta"><div><dt>募集職種</dt><dd>{posting.role_name}</dd></div><div><dt>勤務地・勤務形態</dt><dd>{posting.work_location}</dd></div></dl><section><h2>募集内容</h2><p>{posting.description}</p></section><section><h2>応募条件</h2><p>{posting.requirements}</p></section>
  </article>}</main>;
}
