"use client";

import Link from "next/link";
import Image from "next/image";
import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import {
  ApiError,
  ApiRequestError,
  createCompanyJobPosting,
  JobPostingFields,
  updateCompanyJobPosting,
} from "@/lib/api";

const EMPTY_FIELDS: JobPostingFields = {
  title: "",
  role_name: "",
  work_location: "",
  description: "",
  requirements: "",
};

export default function JobPostingForm({ id, initialValues, initialThumbnailUrl }: { id?: string; initialValues?: JobPostingFields; initialThumbnailUrl?: string | null }) {
  const router = useRouter();
  const [fields, setFields] = useState(initialValues ?? EMPTY_FIELDS);
  const [errors, setErrors] = useState<ApiError[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [thumbnail, setThumbnail] = useState<File | null>(null);
  const [removeThumbnail, setRemoveThumbnail] = useState(false);

  function updateField(field: keyof JobPostingFields, value: string) {
    setFields((current) => ({ ...current, [field]: value }));
  }

  function fieldError(field: keyof JobPostingFields | "thumbnail") {
    return errors.find((error) => error.field === field)?.message;
  }

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (isSubmitting) return;
    setErrors([]);
    setIsSubmitting(true);

    try {
      if (id) await updateCompanyJobPosting(id, fields, thumbnail, removeThumbnail);
      else await createCompanyJobPosting(fields, thumbnail);
      router.push(`/companies/job-postings?saved=${id ? "updated" : "created"}`);
    } catch (error: unknown) {
      if (error instanceof ApiRequestError) {
        if (error.errors.some((item) => item.code === "unauthenticated")) {
          router.replace("/companies/login");
          return;
        }
        if (error.errors.some((item) => item.code === "forbidden")) {
          router.replace("/students/me");
          return;
        }
        setErrors(error.errors);
      } else {
        setErrors([{ field: "base", code: "unexpected", message: "募集の保存に失敗しました。" }]);
      }
      setIsSubmitting(false);
    }
  }

  const baseError = errors.find((error) => error.field === "base")?.message;

  return (
    <form className="form-grid single-column" onSubmit={submit}>
      {baseError && <div className="error-banner" role="alert">{baseError}</div>}
      <JobField label="タイトル" field="title" value={fields.title} maxLength={120} error={fieldError("title")} onChange={updateField} />
      <JobField label="募集職種" field="role_name" value={fields.role_name} maxLength={100} error={fieldError("role_name")} onChange={updateField} />
      <JobField label="勤務地・勤務形態" field="work_location" value={fields.work_location} maxLength={200} error={fieldError("work_location")} onChange={updateField} />
      <JobField label="募集内容" field="description" value={fields.description} maxLength={5000} rows={8} error={fieldError("description")} onChange={updateField} />
      <JobField label="応募条件" field="requirements" value={fields.requirements} maxLength={3000} rows={6} error={fieldError("requirements")} onChange={updateField} />
      <div className="field field-wide">
        <label htmlFor="job-thumbnail">サムネイル画像<span className="optional-label">任意</span></label>
        {initialThumbnailUrl && !removeThumbnail && !thumbnail && <Image className="thumbnail-preview" src={initialThumbnailUrl} alt="現在のサムネイル" width={960} height={480} unoptimized />}
        {thumbnail && <p className="selected-file">選択中: {thumbnail.name}</p>}
        <input id="job-thumbnail" type="file" accept="image/jpeg,image/png,image/webp" onChange={(event) => { setThumbnail(event.target.files?.[0] ?? null); setRemoveThumbnail(false); }} />
        <span className="field-hint">JPEG・PNG・WebP、5MB以下</span>
        {initialThumbnailUrl && !thumbnail && <label className="checkbox-line"><input type="checkbox" checked={removeThumbnail} onChange={(event) => setRemoveThumbnail(event.target.checked)} />現在の画像を削除する</label>}
        {fieldError("thumbnail") && <p className="field-error">{fieldError("thumbnail")}</p>}
      </div>
      <div className="actions">
        <button className="primary-button" type="submit" disabled={isSubmitting}>{isSubmitting ? "保存中…" : id ? "募集を更新" : "募集を公開"}</button>
        <Link className="secondary-link" href="/companies/job-postings">キャンセル</Link>
      </div>
    </form>
  );
}

function JobField({ label, field, value, maxLength, rows, error, onChange }: {
  label: string;
  field: keyof JobPostingFields;
  value: string;
  maxLength: number;
  rows?: number;
  error?: string;
  onChange: (field: keyof JobPostingFields, value: string) => void;
}) {
  const id = `job-${field}`;
  return (
    <div className="field field-wide">
      <label htmlFor={id}>{label}<span className="required-label">必須</span></label>
      {rows ? (
        <textarea id={id} value={value} onChange={(event) => onChange(field, event.target.value)} maxLength={maxLength} rows={rows} aria-invalid={Boolean(error)} required />
      ) : (
        <input id={id} value={value} onChange={(event) => onChange(field, event.target.value)} maxLength={maxLength} aria-invalid={Boolean(error)} required />
      )}
      <span className="field-hint">{value.length} / {maxLength}文字</span>
      {error && <p className="field-error">{error}</p>}
    </div>
  );
}
