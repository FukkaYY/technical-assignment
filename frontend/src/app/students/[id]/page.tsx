"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { ApiRequestError, getStudent, StudentDetail } from "@/lib/api";

export default function StudentDetailPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const [student, setStudent] = useState<StudentDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isNotFound, setIsNotFound] = useState(false);
  const [error, setError] = useState("");
  const [retryKey, setRetryKey] = useState(0);

  useEffect(() => {
    let cancelled = false;

    void getStudent(params.id)
      .then(({ data }) => {
        if (!cancelled) setStudent(data);
      })
      .catch((requestError: unknown) => {
        if (cancelled) return;
        if (requestError instanceof ApiRequestError) {
          if (requestError.errors.some((item) => item.code === "unauthenticated")) {
            router.replace("/companies/login");
            return;
          }
          if (requestError.errors.some((item) => item.code === "forbidden")) {
            router.replace("/students/me");
            return;
          }
          if (requestError.errors.some((item) => item.code === "not_found")) {
            setIsNotFound(true);
            return;
          }
          setError(requestError.errors[0]?.message ?? "学生詳細の読み込みに失敗しました。");
          return;
        }
        setError("学生詳細の読み込みに失敗しました。");
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [params.id, retryKey, router]);

  function retry() {
    setStudent(null);
    setError("");
    setIsNotFound(false);
    setIsLoading(true);
    setRetryKey((current) => current + 1);
  }

  return (
    <main className="student-detail-shell">
      <Link className="back-link" href="/students">← 学生一覧へ戻る</Link>

      {isLoading && <section className="list-state"><p className="loading">学生詳細を読み込んでいます…</p></section>}

      {!isLoading && isNotFound && (
        <section className="list-state">
          <p className="eyebrow">404 NOT FOUND</p>
          <h1>学生が見つかりません</h1>
          <p>対象の学生は存在しないか、削除された可能性があります。</p>
        </section>
      )}

      {!isLoading && error && (
        <section className="list-state error-state" role="alert">
          <h1>学生詳細を表示できません</h1>
          <p>{error}</p>
          <button className="secondary-button compact-button" type="button" onClick={retry}>再試行</button>
        </section>
      )}

      {!isLoading && student && (
        <article className="student-detail-card">
          <header className="student-detail-heading">
            <div>
              <p className="eyebrow">STUDENT PROFILE</p>
              <h1>{student.name}</h1>
              <p className="student-affiliation">{student.school_name} / {student.graduation_year}年卒業予定</p>
              {(student.faculty_name || student.department_name) && <p className="student-affiliation">{[student.faculty_name, student.department_name].filter(Boolean).join(" / ")}</p>}
            </div>
            <div className="message-action">
              <Link className="primary-link" href={`/students/${student.id}/messages`}>この学生にメッセージを送る</Link>
            </div>
          </header>

          <section className="detail-section">
            <h2>興味のある職種</h2>
            <p className="desired-role detail-value">{student.interested_roles.length > 0 ? student.interested_roles.join(" / ") : student.desired_role}</p>
          </section>

          <section className="detail-section">
            <h2>スキル</h2>
            <div className="skill-list" aria-label={`スキル ${student.skills.length}件`}>
              {student.skills.map((skill) => <span key={skill}>{skill}</span>)}
            </div>
          </section>

          {[
            ["自己PR", student.self_promotion],
            ["学生時代に力を入れたこと", student.student_achievement],
            ["研究・ゼミ内容", student.research_summary],
            ["英語スキル", student.english_skills],
            ["保有資格", student.qualifications],
          ].filter(([, value]) => value).map(([label, value]) => <section className="detail-section" key={label}><h2>{label}</h2><p className="self-introduction-full">{value}</p></section>)}
          {![student.self_promotion, student.student_achievement, student.research_summary, student.english_skills, student.qualifications].some(Boolean) && <section className="detail-section"><h2>アピール情報</h2><p className="self-introduction-full">まだ登録されていません。</p></section>}
        </article>
      )}
    </main>
  );
}
