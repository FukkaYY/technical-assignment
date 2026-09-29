"use client";

import { useMemo } from "react";
import type { EducationOptions } from "@/lib/api";

export type EducationValues = {
  schoolType: string;
  schoolQuery: string;
  schoolId: string;
  facultyId: string;
  departmentId: string;
};

export function EducationFields({ options, values, errors, onChange }: {
  options: EducationOptions | null;
  values: EducationValues;
  errors: Record<string, string>;
  onChange: (values: EducationValues) => void;
}) {
  const schools = useMemo(() => options?.schools.filter((school) =>
    school.school_type === values.schoolType && school.name.toLocaleLowerCase().includes(values.schoolQuery.trim().toLocaleLowerCase())
  ) ?? [], [options, values.schoolQuery, values.schoolType]);
  const school = options?.schools.find((item) => String(item.id) === values.schoolId);
  const faculty = school?.faculties.find((item) => String(item.id) === values.facultyId);
  const hasAffiliations = values.schoolType === "university" || values.schoolType === "graduate_school";
  const unitLabel = values.schoolType === "graduate_school" ? "研究科" : "学部";

  function set(patch: Partial<EducationValues>) { onChange({ ...values, ...patch }); }

  return <>
    <Field label="学校の種類" name="schoolType" required error={errors.schoolType}>
      <select id="schoolType" value={values.schoolType} onChange={(event) => set({ schoolType: event.target.value, schoolQuery: "", schoolId: "", facultyId: "", departmentId: "" })} required>
        <option value="">選択してください</option>
        {options?.school_types.map((type) => <option key={type.value} value={type.value}>{type.label}</option>)}
      </select>
    </Field>
    <Field label="学校名を検索" name="schoolQuery" hint="入力すると候補を絞り込めます">
      <input id="schoolQuery" value={values.schoolQuery} onChange={(event) => set({ schoolQuery: event.target.value, schoolId: "", facultyId: "", departmentId: "" })} disabled={!values.schoolType} placeholder="例: デモ大学" />
    </Field>
    <Field label="学校名" name="schoolId" required error={errors.schoolId}>
      <select id="schoolId" value={values.schoolId} onChange={(event) => set({ schoolId: event.target.value, facultyId: "", departmentId: "" })} disabled={!values.schoolType} required>
        <option value="">候補から選択してください</option>
        {schools.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
      </select>
    </Field>
    {hasAffiliations && school && <>
      <Field label={unitLabel} name="facultyId" error={errors.facultyId}>
        <select id="facultyId" value={values.facultyId} onChange={(event) => set({ facultyId: event.target.value, departmentId: "" })}>
          <option value="">未選択</option>
          {school.faculties.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
        </select>
      </Field>
      <Field label="学科・専攻" name="departmentId" error={errors.departmentId}>
        <select id="departmentId" value={values.departmentId} onChange={(event) => set({ departmentId: event.target.value })} disabled={!faculty}>
          <option value="">未選択</option>
          {faculty?.departments.map((item) => <option key={item.id} value={item.id}>{item.name}</option>)}
        </select>
      </Field>
    </>}
  </>;
}

function Field({ label, name, hint, required, error, children }: { label: string; name: string; hint?: string; required?: boolean; error?: string; children: React.ReactNode }) {
  const descriptionId = error ? `${name}-error` : hint ? `${name}-hint` : undefined;
  return <div className="field field-wide"><label htmlFor={name}>{label} {required && <span className="required-label">必須</span>}</label>{hint && <span id={`${name}-hint`} className="field-hint">{hint}</span>}<div aria-describedby={descriptionId} aria-invalid={Boolean(error)}>{children}</div>{error && <p id={`${name}-error`} className="field-error" role="alert">{error}</p>}</div>;
}
