"use client";

import { useState } from "react";
import { ApiRequestError, setJobPostingInterest } from "@/lib/api";

export default function JobInterestButton({ id, interested, onChanged }: {
  id: number;
  interested: boolean;
  onChanged: (interested: boolean) => void;
}) {
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState("");

  async function toggleInterest() {
    if (isSaving) return;
    setIsSaving(true);
    setError("");
    try {
      const nextValue = !interested;
      await setJobPostingInterest(id, nextValue);
      onChanged(nextValue);
    } catch (requestError: unknown) {
      setError(requestError instanceof ApiRequestError ? requestError.errors[0]?.message ?? "更新できませんでした。" : "更新できませんでした。");
    } finally {
      setIsSaving(false);
    }
  }

  return <div className="interest-control"><button className={`interest-button${interested ? " active" : ""}`} type="button" aria-pressed={interested} onClick={toggleInterest} disabled={isSaving}>{isSaving ? "更新中…" : interested ? "気になる！済み" : "気になる！"}</button>{error && <p className="field-error" role="alert">{error}</p>}</div>;
}
