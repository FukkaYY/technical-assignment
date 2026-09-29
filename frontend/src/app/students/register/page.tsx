"use client";

import { FormEvent, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiRequestError, getEducationOptions, registerStudent, type EducationOptions } from "@/lib/api";
import { EducationFields, type EducationValues } from "@/components/EducationFields";
import { InterestedRolesField } from "@/components/InterestedRolesField";

type FormValues = {
  lastName: string;
  firstName: string;
  email: string;
  password: string;
  passwordConfirmation: string;
  education: EducationValues;
  graduationYear: string;
  interestedRoles: string[];
  skills: string;
};

const initialValues: FormValues = {
  lastName: "",
  firstName: "",
  email: "",
  password: "",
  passwordConfirmation: "",
  education: { schoolType: "", schoolQuery: "", schoolId: "", facultyId: "", departmentId: "" },
  graduationYear: "",
  interestedRoles: [],
  skills: "",
};

export default function StudentRegistrationPage() {
  const router = useRouter();
  const [values, setValues] = useState(initialValues);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [educationOptions, setEducationOptions] = useState<EducationOptions | null>(null);

  useEffect(() => {
    void getEducationOptions().then(({ data }) => setEducationOptions(data)).catch(() => setErrors((current) => ({ ...current, base: "学校情報の読み込みに失敗しました。" })));
  }, []);

  function update(field: keyof FormValues, value: string) {
    setValues((current) => ({ ...current, [field]: value }));
    setErrors((current) => {
      const next = { ...current };
      delete next[field];
      return next;
    });
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setErrors({});

    try {
      await registerStudent({
        last_name: values.lastName,
        first_name: values.firstName,
        email: values.email,
        password: values.password,
        password_confirmation: values.passwordConfirmation,
        school_id: Number(values.education.schoolId),
        faculty_id: values.education.facultyId ? Number(values.education.facultyId) : null,
        department_id: values.education.departmentId ? Number(values.education.departmentId) : null,
        graduation_year: Number(values.graduationYear),
        interested_roles: values.interestedRoles,
        skills: values.skills.split(","),
      });
      router.push("/students/me");
    } catch (error) {
      if (error instanceof ApiRequestError) {
        const fieldErrors: Record<string, string> = {};
        for (const item of error.errors) {
          const frontendField = item.field.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase());
          fieldErrors[frontendField] ??= item.message;
        }
        setErrors(fieldErrors);
      } else {
        setErrors({ base: "通信に失敗しました。時間をおいて再度お試しください。" });
      }
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="page-shell">
      <section className="form-card" aria-labelledby="registration-title">
        <p className="eyebrow">STUDENT REGISTRATION</p>
        <h1 id="registration-title">学生登録</h1>
        <p className="intro">企業があなたの経験を知れるように、プロフィールを登録してください。</p>

        {errors.base && <div className="error-banner" role="alert">{errors.base}</div>}

        <form onSubmit={handleSubmit} noValidate>
          <div className="form-grid single-column">
            <div className="name-fields">
              <Field label="姓（Family name）" name="lastName" required error={errors.lastName}><input id="lastName" value={values.lastName} onChange={(event) => update("lastName", event.target.value)} maxLength={50} autoComplete="family-name" required /></Field>
              <Field label="名（Given name）" name="firstName" required error={errors.firstName}><input id="firstName" value={values.firstName} onChange={(event) => update("firstName", event.target.value)} maxLength={50} autoComplete="given-name" required /></Field>
            </div>

            <Field label="メールアドレス" name="email" required error={errors.email} wide>
              <input id="email" type="email" value={values.email} onChange={(event) => update("email", event.target.value)} autoComplete="email" required />
            </Field>

            <Field label="パスワード" name="password" hint="8文字以上" required error={errors.password}>
              <input id="password" type="password" value={values.password} onChange={(event) => update("password", event.target.value)} minLength={8} autoComplete="new-password" required />
            </Field>

            <Field label="パスワード確認" name="passwordConfirmation" required error={errors.passwordConfirmation}>
              <input id="passwordConfirmation" type="password" value={values.passwordConfirmation} onChange={(event) => update("passwordConfirmation", event.target.value)} minLength={8} autoComplete="new-password" required />
            </Field>

            <EducationFields options={educationOptions} values={values.education} errors={errors} onChange={(education) => setValues((current) => ({ ...current, education }))} />

            <Field label="卒業予定年" name="graduationYear" required error={errors.graduationYear}>
              <select id="graduationYear" value={values.graduationYear} onChange={(event) => update("graduationYear", event.target.value)} required><option value="">選択してください</option>{[0, 1, 2].map((offset) => { const year = new Date().getFullYear() + offset; return <option key={year} value={year}>{year}年</option>; })}</select>
            </Field>

            <InterestedRolesField value={values.interestedRoles} error={errors.interestedRoles} onChange={(interestedRoles) => setValues((current) => ({ ...current, interestedRoles }))} />

            <Field label="スキル" name="skills" hint="カンマ区切り、最大20件" error={errors.skills} wide>
              <input id="skills" value={values.skills} onChange={(event) => update("skills", event.target.value)} placeholder="Ruby, TypeScript, PostgreSQL" />
            </Field>

          </div>

          <button className="primary-button" type="submit" disabled={isSubmitting}>
            {isSubmitting ? "登録中…" : "プロフィールを登録"}
          </button>
        </form>
      </section>
    </main>
  );
}

function Field({
  label,
  name,
  hint,
  required,
  error,
  wide,
  children,
}: {
  label: string;
  name: string;
  hint?: string;
  required?: boolean;
  error?: string;
  wide?: boolean;
  children: React.ReactNode;
}) {
  const descriptionId = error ? `${name}-error` : hint ? `${name}-hint` : undefined;

  return (
    <div className={`field${wide ? " field-wide" : ""}`}>
      <label htmlFor={name}>
        {label} {required && <span className="required-label">必須</span>}
      </label>
      {hint && <span id={`${name}-hint`} className="field-hint">{hint}</span>}
      <div aria-describedby={descriptionId} aria-invalid={Boolean(error)}>{children}</div>
      {error && <p id={`${name}-error`} className="field-error" role="alert">{error}</p>}
    </div>
  );
}
