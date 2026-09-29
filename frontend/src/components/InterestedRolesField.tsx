"use client";

export const INTERESTED_ROLE_OPTIONS = [
  "ソフトウェアエンジニア",
  "データサイエンティスト",
  "AI・機械学習エンジニア",
  "プロダクトマネージャー",
  "UI・UXデザイナー",
  "セールス",
  "マーケティング",
  "コーポレート",
  "まだ決めていない",
] as const;

export function InterestedRolesField({ value, error, onChange }: { value: string[]; error?: string; onChange: (roles: string[]) => void }) {
  function toggle(role: string) {
    if (value.includes(role)) {
      onChange(value.filter((item) => item !== role));
      return;
    }
    if (role === "まだ決めていない") {
      onChange([role]);
      return;
    }
    onChange([...value.filter((item) => item !== "まだ決めていない"), role]);
  }

  return <fieldset className="interest-role-field" aria-describedby={error ? "interestedRoles-error" : "interestedRoles-hint"}>
    <legend>興味のある職種 <span className="required-label">必須</span></legend>
    <p id="interestedRoles-hint" className="field-hint">最大3件まで選択できます</p>
    <div className="interest-role-options">
      {INTERESTED_ROLE_OPTIONS.map((role) => {
        const checked = value.includes(role);
        const disabled = !checked && role !== "まだ決めていない" && value.filter((item) => item !== "まだ決めていない").length >= 3;
        return <label key={role} className={checked ? "selected" : ""}><input type="checkbox" checked={checked} disabled={disabled} onChange={() => toggle(role)} />{role}</label>;
      })}
    </div>
    {error && <p id="interestedRoles-error" className="field-error" role="alert">{error}</p>}
  </fieldset>;
}
