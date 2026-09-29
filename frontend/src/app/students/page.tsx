"use client";

import Link from "next/link";
import { FormEvent, Suspense, useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  ApiRequestError,
  CompanyProfile,
  EducationOptions,
  getEducationOptions,
  getCurrentUser,
  getStudents,
  logout,
  StudentListItem,
  StudentListMeta,
} from "@/lib/api";
import { INTERESTED_ROLE_OPTIONS } from "@/components/InterestedRolesField";

export default function StudentsPage() {
  return (
    <Suspense fallback={<main className="students-shell"><section className="list-state"><p className="loading">学生一覧を読み込んでいます…</p></section></main>}>
      <StudentsContent />
    </Suspense>
  );
}

function StudentsContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const appliedSchoolType = searchParams.get("school_type") ?? "";
  const appliedSchoolId = searchParams.get("school_id") ?? "";
  const appliedGraduationYear = searchParams.get("graduation_year") ?? "";
  const appliedInterestedRole = searchParams.get("interested_role") ?? "";
  const requestedPage = searchParams.get("page") ?? "1";
  const page = /^\d+$/.test(requestedPage) && Number(requestedPage) > 0 ? Number(requestedPage) : 1;
  const [companyProfile, setCompanyProfile] = useState<CompanyProfile | null>(null);
  const [students, setStudents] = useState<StudentListItem[]>([]);
  const [meta, setMeta] = useState<StudentListMeta | null>(null);
  const [educationOptions, setEducationOptions] = useState<EducationOptions | null>(null);
  const [schoolType, setSchoolType] = useState(appliedSchoolType);
  const [schoolId, setSchoolId] = useState(appliedSchoolId);
  const [graduationYear, setGraduationYear] = useState(appliedGraduationYear);
  const [interestedRole, setInterestedRole] = useState(appliedInterestedRole);
  const [retryKey, setRetryKey] = useState(0);
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  useEffect(() => {
    let cancelled = false;

    void Promise.all([
      getCurrentUser(),
      getEducationOptions(),
      getStudents(page, {
        schoolType: appliedSchoolType,
        schoolId: appliedSchoolId,
        graduationYear: appliedGraduationYear,
        interestedRole: appliedInterestedRole,
      }),
    ])
      .then(([currentUserResponse, educationOptionsResponse, studentsResponse]) => {
        if (cancelled) return;
        if (currentUserResponse.data.user.role !== "company") {
          router.replace("/students/me");
          return;
        }
        if (!currentUserResponse.data.company_profile) {
          setError("企業プロフィールを表示できません。");
          return;
        }

        setCompanyProfile(currentUserResponse.data.company_profile);
        setEducationOptions(educationOptionsResponse.data);
        setStudents(studentsResponse.data);
        setMeta(studentsResponse.meta);
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
          setError(requestError.errors[0]?.message ?? "学生一覧の読み込みに失敗しました。");
        } else {
          setError("学生一覧の読み込みに失敗しました。");
        }
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [appliedInterestedRole, appliedGraduationYear, appliedSchoolId, appliedSchoolType, page, retryKey, router]);

  function changePage(nextPage: number) {
    setError("");
    setIsLoading(true);
    const params = new URLSearchParams(searchParams.toString());
    if (nextPage === 1) params.delete("page");
    else params.set("page", String(nextPage));
    router.push(`/students${params.size > 0 ? `?${params.toString()}` : ""}`);
  }

  function applySearch(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const params = new URLSearchParams();
    const normalizedSchoolType = schoolType.trim();
    const normalizedSchoolId = schoolId.trim();
    const normalizedGraduationYear = graduationYear.trim();
    const normalizedInterestedRole = interestedRole.trim();
    if (normalizedSchoolType) params.set("school_type", normalizedSchoolType);
    if (normalizedSchoolId) params.set("school_id", normalizedSchoolId);
    if (normalizedGraduationYear) params.set("graduation_year", normalizedGraduationYear);
    if (normalizedInterestedRole) params.set("interested_role", normalizedInterestedRole);
    setError("");
    setIsLoading(true);
    router.push(`/students${params.size > 0 ? `?${params.toString()}` : ""}`);
  }

  function clearSearch() {
    setSchoolType("");
    setSchoolId("");
    setGraduationYear("");
    setInterestedRole("");
    setError("");
    setIsLoading(true);
    router.push("/students");
  }

  function retry() {
    setError("");
    setIsLoading(true);
    setRetryKey((current) => current + 1);
  }

  async function handleLogout() {
    setError("");
    setIsLoggingOut(true);
    try {
      await logout();
      router.replace("/");
    } catch {
      setError("ログアウトに失敗しました。");
      setIsLoggingOut(false);
    }
  }

  return (
    <main className="students-shell">
      <header className="dashboard-header">
        <div>
          <p className="eyebrow">STUDENT CANDIDATES</p>
          <h1>学生一覧</h1>
          {companyProfile && <p className="company-context">{companyProfile.company_name}</p>}
        </div>
        {companyProfile && (
          <div className="header-actions"><Link className="secondary-link" href="/companies/messages">メッセージ一覧</Link><Link className="secondary-link" href="/companies/job-postings">募集を管理</Link><button className="danger-button header-button" type="button" onClick={handleLogout} disabled={isLoggingOut}>{isLoggingOut ? "ログアウト中…" : "ログアウト"}</button></div>
        )}
      </header>

      <form className="student-search" aria-label="学生の絞り込み" onSubmit={applySearch}>
        <div className="student-search-fields">
          <label>
            <span>学校の種類</span>
            <select value={schoolType} onChange={(event) => { setSchoolType(event.target.value); setSchoolId(""); }}>
              <option value="">すべて</option>
              {educationOptions?.school_types.map((type) => <option key={type.value} value={type.value}>{type.label}</option>)}
            </select>
          </label>
          <label>
            <span>学校名</span>
            <select value={schoolId} onChange={(event) => setSchoolId(event.target.value)} disabled={!schoolType}>
              <option value="">すべて</option>
              {educationOptions?.schools.filter((school) => school.school_type === schoolType).map((school) => <option key={school.id} value={school.id}>{school.name}</option>)}
            </select>
          </label>
          <label>
            <span>卒業予定年</span>
            <select value={graduationYear} onChange={(event) => setGraduationYear(event.target.value)}>
              <option value="">すべて</option>
              {[0, 1, 2].map((offset) => { const year = new Date().getFullYear() + offset; return <option key={year} value={year}>{year}年</option>; })}
            </select>
          </label>
          <label>
            <span>興味のある職種</span>
            <select value={interestedRole} onChange={(event) => setInterestedRole(event.target.value)}><option value="">すべて</option>{INTERESTED_ROLE_OPTIONS.map((role) => <option key={role} value={role}>{role}</option>)}</select>
          </label>
        </div>
        <div className="student-search-actions">
          <button className="primary-button" type="submit">絞り込む</button>
          <button className="secondary-button" type="button" onClick={clearSearch}>条件をクリア</button>
        </div>
      </form>

      {error && (
        <section className="list-state error-state" role="alert">
          <p>{error}</p>
          <button className="secondary-button compact-button" type="button" onClick={retry}>再試行</button>
        </section>
      )}

      {isLoading && <section className="list-state"><p className="loading">学生一覧を読み込んでいます…</p></section>}

      {!isLoading && !error && meta && (
        <>
          <div className="list-summary">
            <p>{hasSearchConditions(appliedSchoolType, appliedSchoolId, appliedGraduationYear, appliedInterestedRole) ? `${meta.total_count}人が絞り込み条件に一致しました` : `${meta.total_count}人の学生が登録されています`}</p>
            {meta.total_pages > 0 && <p>{meta.page} / {meta.total_pages}ページ</p>}
          </div>

          {students.length === 0 ? (
            <section className="list-state empty-state">
              <h2>{hasSearchConditions(appliedSchoolType, appliedSchoolId, appliedGraduationYear, appliedInterestedRole) ? "絞り込み条件に一致する学生がいません" : "表示できる学生がいません"}</h2>
              <p>{hasSearchConditions(appliedSchoolType, appliedSchoolId, appliedGraduationYear, appliedInterestedRole) ? "条件を変更するか、条件をクリアしてください。" : meta.total_count === 0 ? "学生が登録されるとここに表示されます。" : "このページには学生がいません。"}</p>
              {hasSearchConditions(appliedSchoolType, appliedSchoolId, appliedGraduationYear, appliedInterestedRole) && <button className="secondary-button compact-button" type="button" onClick={clearSearch}>条件をクリア</button>}
            </section>
          ) : (
            <section className="student-grid" aria-label="学生一覧">
              {students.map((student) => <StudentCard key={student.id} student={student} />)}
            </section>
          )}

          {meta.total_pages > 0 && (
            <nav className="pagination" aria-label="学生一覧のページ移動">
              <button type="button" onClick={() => changePage(page - 1)} disabled={!meta.has_previous}>前へ</button>
              <span aria-current="page">{meta.page} / {meta.total_pages}</span>
              <button type="button" onClick={() => changePage(page + 1)} disabled={!meta.has_next}>次へ</button>
            </nav>
          )}
        </>
      )}
    </main>
  );
}

function hasSearchConditions(schoolType: string, schoolId: string, graduationYear: string, interestedRole: string) {
  return Boolean(schoolType || schoolId || graduationYear || interestedRole);
}

function StudentCard({ student }: { student: StudentListItem }) {
  const hiddenSkillCount = student.skills_count - student.skills.length;
  const registeredAt = new Intl.DateTimeFormat("ja-JP", { dateStyle: "medium" }).format(new Date(student.registered_at));

  return (
    <article className="student-card">
      <div className="student-card-heading">
        <div>
          <h2>{student.name}</h2>
          <p>{student.school_name} / {student.graduation_year}年卒業予定</p>
        </div>
        <span className="registered-at">{registeredAt}登録</span>
      </div>
      <p className="desired-role">{student.interested_roles.length > 0 ? student.interested_roles.join(" / ") : student.desired_role}</p>
      <div className="skill-list" aria-label={`スキル ${student.skills_count}件`}>
        {student.skills.map((skill) => <span key={skill}>{skill}</span>)}
        {hiddenSkillCount > 0 && <span>+{hiddenSkillCount}</span>}
      </div>
      <p className="student-introduction">{student.self_introduction_excerpt}</p>
      <Link className="detail-link" href={`/students/${student.id}`}>詳細を見る</Link>
    </article>
  );
}
