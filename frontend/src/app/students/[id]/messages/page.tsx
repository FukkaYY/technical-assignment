"use client";

import Link from "next/link";
import { FormEvent, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import {
  ApiRequestError,
  cancelScheduleProposal,
  createScheduleProposal,
  getStudentMessages,
  MessageItem,
  ScheduleProposal,
  sendStudentMessage,
} from "@/lib/api";
import ScheduleProposalCard from "@/components/schedule-proposal-card";

const MAX_BODY_LENGTH = 2_000;

export default function StudentMessagesPage() {
  const params = useParams<{ id: string }>();
  const router = useRouter();
  const [studentName, setStudentName] = useState("");
  const [messages, setMessages] = useState<MessageItem[]>([]);
  const [conversationId, setConversationId] = useState<number | null>(null);
  const [proposals, setProposals] = useState<ScheduleProposal[]>([]);
  const [body, setBody] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [isNotFound, setIsNotFound] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [loadError, setLoadError] = useState("");
  const [sendError, setSendError] = useState("");
  const [retryKey, setRetryKey] = useState(0);
  const [scheduleFields, setScheduleFields] = useState({ starts_at: "", duration_minutes: "60", location: "", note: "" });
  const [scheduleError, setScheduleError] = useState("");
  const [isScheduling, setIsScheduling] = useState(false);
  const [changingProposalId, setChangingProposalId] = useState<number | null>(null);

  useEffect(() => {
    let cancelled = false;

    void getStudentMessages(params.id)
      .then(({ data }) => {
        if (cancelled) return;
        setStudentName(data.student.name);
        setMessages(data.messages);
        setConversationId(data.conversation_id);
        setProposals(data.schedule_proposals);
      })
      .catch((requestError: unknown) => {
        if (cancelled) return;
        handleAccessError(requestError, router, () => setIsNotFound(true), setLoadError);
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [params.id, retryKey, router]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const normalizedBody = body.trim();
    if (!normalizedBody || normalizedBody.length > MAX_BODY_LENGTH || isSending) return;

    setSendError("");
    setIsSending(true);
    try {
      const response = await sendStudentMessage(params.id, body);
      setMessages((current) => [...current, response.data.message]);
      setConversationId(response.data.conversation_id);
      setBody("");
    } catch (requestError: unknown) {
      handleAccessError(requestError, router, () => setIsNotFound(true), setSendError);
    } finally {
      setIsSending(false);
    }
  }

  async function submitSchedule(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (isScheduling) return;
    setScheduleError("");
    setIsScheduling(true);
    try {
      const { data } = await createScheduleProposal(params.id, { ...scheduleFields, duration_minutes: Number(scheduleFields.duration_minutes) });
      setProposals((current) => [...current, data]);
      setScheduleFields({ starts_at: "", duration_minutes: "60", location: "", note: "" });
    } catch (requestError: unknown) {
      handleAccessError(requestError, router, () => setIsNotFound(true), setScheduleError);
    } finally {
      setIsScheduling(false);
    }
  }

  async function cancelProposal(id: number) {
    setChangingProposalId(id);
    setScheduleError("");
    try {
      const { data } = await cancelScheduleProposal(id);
      setProposals((current) => current.map((proposal) => proposal.id === id ? data : proposal));
    } catch (requestError: unknown) {
      handleAccessError(requestError, router, () => setIsNotFound(true), setScheduleError);
    } finally {
      setChangingProposalId(null);
    }
  }

  function retry() {
    setLoadError("");
    setIsNotFound(false);
    setIsLoading(true);
    setRetryKey((current) => current + 1);
  }

  const normalizedLength = body.trim().length;
  const canSend = normalizedLength > 0 && normalizedLength <= MAX_BODY_LENGTH && !isSending;

  return (
    <main className="message-shell">
      <Link className="back-link" href={`/students/${params.id}`}>← 学生詳細へ戻る</Link>

      {isLoading && <section className="list-state"><p className="loading">メッセージ履歴を読み込んでいます…</p></section>}

      {!isLoading && isNotFound && (
        <section className="list-state">
          <p className="eyebrow">404 NOT FOUND</p>
          <h1>学生が見つかりません</h1>
          <p>対象の学生は存在しないか、削除された可能性があります。</p>
        </section>
      )}

      {!isLoading && loadError && (
        <section className="list-state error-state" role="alert">
          <h1>メッセージ履歴を表示できません</h1>
          <p>{loadError}</p>
          <button className="secondary-button compact-button" type="button" onClick={retry}>再試行</button>
        </section>
      )}

      {!isLoading && !isNotFound && !loadError && (
        <div className="message-layout">
          <header className="message-header">
            <p className="eyebrow">SCOUT MESSAGE</p>
            <h1>{studentName}さんへのメッセージ</h1>
            <p>送信したメッセージは学生本人が受信画面から確認できます。</p>
          </header>

          <section className="message-history" aria-label="会話履歴">
            <h2>会話履歴</h2>
            {messages.length === 0 ? (
              <div className="message-empty">
                <p>まだメッセージを送信していません。</p>
              </div>
            ) : (
              <ol>
                {messages.map((message) => (
                  <li className={message.sender_role === "student" ? "message-from-student" : "message-from-company"} key={message.id}>
                    <strong>{message.sender_role === "student" ? `${studentName}さん` : "自社"}</strong>
                    <p>{message.body}</p>
                    <time dateTime={message.sent_at}>{formatSentAt(message.sent_at)}</time>
                  </li>
                ))}
              </ol>
            )}
          </section>

          <section className="schedule-section" aria-label="面談予定">
            <h2>面談予定</h2>
            {proposals.length === 0 ? <p className="message-empty">面談予定はまだありません。</p> : proposals.map((proposal) => (
              <ScheduleProposalCard key={proposal.id} proposal={proposal} actions={proposal.status === "pending" ? <button className="secondary-button compact-button" type="button" onClick={() => cancelProposal(proposal.id)} disabled={changingProposalId === proposal.id}>{changingProposalId === proposal.id ? "取消中…" : "予定を取り消す"}</button> : undefined} />
            ))}
            {conversationId ? (
              <form className="schedule-form" aria-label="面談予定の提案" onSubmit={submitSchedule}>
                <h3>新しい面談予定を提案</h3>
                <div className="schedule-form-grid">
                  <label>開始日時（日本時間）<input type="datetime-local" step="900" value={scheduleFields.starts_at} onChange={(event) => setScheduleFields((current) => ({ ...current, starts_at: event.target.value }))} disabled={isScheduling} required /></label>
                  <label>所要時間<select value={scheduleFields.duration_minutes} onChange={(event) => setScheduleFields((current) => ({ ...current, duration_minutes: event.target.value }))} disabled={isScheduling} required>{[15, 30, 45, 60, 75, 90, 105, 120].map((minutes) => <option key={minutes} value={minutes}>{formatDuration(minutes)}</option>)}</select></label>
                  <label className="field-wide">実施方法・場所<input value={scheduleFields.location} onChange={(event) => setScheduleFields((current) => ({ ...current, location: event.target.value }))} maxLength={200} disabled={isScheduling} required /></label>
                  <label className="field-wide">補足（任意）<textarea value={scheduleFields.note} onChange={(event) => setScheduleFields((current) => ({ ...current, note: event.target.value }))} maxLength={1000} rows={3} disabled={isScheduling} /></label>
                </div>
                <button className="primary-button" type="submit" disabled={isScheduling}>{isScheduling ? "提案中…" : "面談予定を提案"}</button>
              </form>
            ) : <p className="schedule-hint">面談予定を提案するには、先にメッセージを送信してください。</p>}
            {scheduleError && <div className="error-banner" role="alert">{scheduleError}</div>}
          </section>

          <form className="message-form" onSubmit={handleSubmit}>
            <label htmlFor="message-body">メッセージ本文</label>
            <textarea
              id="message-body"
              value={body}
              onChange={(event) => setBody(event.target.value)}
              maxLength={MAX_BODY_LENGTH}
              rows={8}
              disabled={isSending}
              aria-describedby="message-count"
              required
            />
            <div className="message-form-footer">
              <span id="message-count">{body.length} / {MAX_BODY_LENGTH}文字</span>
              <button className="primary-button" type="submit" disabled={!canSend}>
                {isSending ? "送信中…" : "メッセージを送信"}
              </button>
            </div>
            {sendError && <div className="error-banner send-error" role="alert">{sendError} 入力内容を保持しています。</div>}
          </form>
        </div>
      )}
    </main>
  );
}

function handleAccessError(
  requestError: unknown,
  router: ReturnType<typeof useRouter>,
  onNotFound: () => void,
  setError: (message: string) => void,
) {
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
      onNotFound();
      return;
    }
    setError(requestError.errors[0]?.message ?? "メッセージの処理に失敗しました。");
    return;
  }
  setError("メッセージの処理に失敗しました。");
}

function formatSentAt(value: string) {
  return new Intl.DateTimeFormat("ja-JP", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}

function formatDuration(minutes: number) {
  if (minutes < 60) return `${minutes}分`;
  const remainingMinutes = minutes % 60;
  return `${Math.floor(minutes / 60)}時間${remainingMinutes > 0 ? `${remainingMinutes}分` : ""}`;
}
