"use client";

import Link from "next/link";
import { FormEvent, useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { acceptScheduleProposal, ApiRequestError, ConversationDetail, declineScheduleProposal, getConversation, markConversationRead, markScheduleProposalsSeen, replyToConversation } from "@/lib/api";
import ScheduleProposalCard from "@/components/schedule-proposal-card";

const MAX_BODY_LENGTH = 2_000;

export default function StudentMessageDetailPage() {
  const params = useParams<{ conversationId: string }>();
  const router = useRouter();
  const [conversation, setConversation] = useState<ConversationDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isNotFound, setIsNotFound] = useState(false);
  const [error, setError] = useState("");
  const [replyError, setReplyError] = useState("");
  const [body, setBody] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [retryKey, setRetryKey] = useState(0);
  const [scheduleError, setScheduleError] = useState("");
  const [changingProposalId, setChangingProposalId] = useState<number | null>(null);

  useEffect(() => {
    let cancelled = false;

    void getConversation(params.conversationId)
      .then(async ({ data }) => {
        if (cancelled) return;
        const latestMessage = data.messages[data.messages.length - 1];
        if (latestMessage) await markConversationRead(params.conversationId, latestMessage.id);
        const latestProposal = data.schedule_proposals[data.schedule_proposals.length - 1];
        if (latestProposal) await markScheduleProposalsSeen(params.conversationId, latestProposal.id);
        if (!cancelled) setConversation(data);
      })
      .catch((requestError: unknown) => {
        if (cancelled) return;
        if (requestError instanceof ApiRequestError) {
          if (requestError.errors.some((item) => item.code === "unauthenticated")) {
            router.replace("/students/login");
            return;
          }
          if (requestError.errors.some((item) => item.code === "forbidden")) {
            router.replace("/students");
            return;
          }
          if (requestError.errors.some((item) => item.code === "not_found")) {
            setIsNotFound(true);
            return;
          }
          setError(requestError.errors[0]?.message ?? "メッセージの読み込みに失敗しました。");
          return;
        }
        setError("メッセージの読み込みに失敗しました。");
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [params.conversationId, retryKey, router]);

  function retry() {
    setConversation(null);
    setError("");
    setIsNotFound(false);
    setIsLoading(true);
    setRetryKey((current) => current + 1);
  }

  async function respondToProposal(id: number, response: "accept" | "decline") {
    setChangingProposalId(id);
    setScheduleError("");
    try {
      const result = response === "accept" ? await acceptScheduleProposal(id) : await declineScheduleProposal(id);
      setConversation((current) => current ? { ...current, schedule_proposals: current.schedule_proposals.map((proposal) => proposal.id === id ? result.data : proposal) } : current);
    } catch (requestError: unknown) {
      if (requestError instanceof ApiRequestError) setScheduleError(requestError.errors[0]?.message ?? "予定への回答に失敗しました。");
      else setScheduleError("予定への回答に失敗しました。");
    } finally {
      setChangingProposalId(null);
    }
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const normalizedBody = body.trim();
    if (!normalizedBody || normalizedBody.length > MAX_BODY_LENGTH || isSending) return;

    setReplyError("");
    setIsSending(true);
    try {
      const response = await replyToConversation(params.conversationId, body);
      setConversation((current) => current ? { ...current, messages: [...current.messages, response.data.message] } : current);
      setBody("");
    } catch (requestError: unknown) {
      if (requestError instanceof ApiRequestError) {
        if (requestError.errors.some((item) => item.code === "unauthenticated")) {
          router.replace("/students/login");
          return;
        }
        if (requestError.errors.some((item) => item.code === "forbidden")) {
          router.replace("/students");
          return;
        }
        if (requestError.errors.some((item) => item.code === "not_found")) {
          setConversation(null);
          setIsNotFound(true);
          return;
        }
        setReplyError(requestError.errors[0]?.message ?? "返信の送信に失敗しました。");
      } else {
        setReplyError("返信の送信に失敗しました。");
      }
    } finally {
      setIsSending(false);
    }
  }

  const normalizedLength = body.trim().length;
  const canSend = normalizedLength > 0 && normalizedLength <= MAX_BODY_LENGTH && !isSending;

  return (
    <main className="message-shell">
      <Link className="back-link" href="/students/messages">← 受信メッセージへ戻る</Link>

      {isLoading && <section className="list-state"><p className="loading">メッセージを読み込んでいます…</p></section>}

      {!isLoading && isNotFound && (
        <section className="list-state">
          <p className="eyebrow">404 NOT FOUND</p>
          <h1>会話が見つかりません</h1>
          <p>この会話は存在しないか、閲覧できません。</p>
        </section>
      )}

      {!isLoading && error && (
        <section className="list-state error-state" role="alert">
          <h1>メッセージを表示できません</h1>
          <p>{error}</p>
          <button className="secondary-button compact-button" type="button" onClick={retry}>再試行</button>
        </section>
      )}

      {!isLoading && conversation && (
        <article className="received-conversation">
          <header className="message-header">
            <p className="eyebrow">MESSAGE FROM</p>
            <h1>{conversation.company.company_name}</h1>
            <p>企業からのメッセージを確認し、この会話へ返信できます。</p>
          </header>
          <section className="received-message-history" aria-label="会話履歴">
            {conversation.messages.map((message) => (
              <div className={`received-message ${message.sender_role === "student" ? "message-from-student" : "message-from-company"}`} key={message.id}>
                <strong>{message.sender_role === "student" ? "あなた" : conversation.company.company_name}</strong>
                <p>{message.body}</p>
                <time dateTime={message.sent_at}>{formatSentAt(message.sent_at)}</time>
              </div>
            ))}
          </section>
          {conversation.schedule_proposals.length > 0 && (
            <section className="schedule-section" aria-label="面談予定">
              <h2>面談予定</h2>
              {conversation.schedule_proposals.map((proposal) => (
                <ScheduleProposalCard key={proposal.id} proposal={proposal} actions={proposal.status === "pending" ? <div className="schedule-actions"><button className="primary-button compact-button" type="button" onClick={() => respondToProposal(proposal.id, "accept")} disabled={changingProposalId === proposal.id}>承諾する</button><button className="secondary-button compact-button" type="button" onClick={() => respondToProposal(proposal.id, "decline")} disabled={changingProposalId === proposal.id}>辞退する</button></div> : undefined} />
              ))}
              {scheduleError && <div className="error-banner" role="alert">{scheduleError}</div>}
            </section>
          )}
          <form className="message-form" aria-label="返信フォーム" onSubmit={handleSubmit}>
            <label htmlFor="reply-body">返信本文</label>
            <textarea
              id="reply-body"
              value={body}
              onChange={(event) => setBody(event.target.value)}
              maxLength={MAX_BODY_LENGTH}
              rows={6}
              disabled={isSending}
              aria-describedby="reply-count"
              required
            />
            <div className="message-form-footer">
              <span id="reply-count">{body.length} / {MAX_BODY_LENGTH}文字</span>
              <button className="primary-button" type="submit" disabled={!canSend}>
                {isSending ? "返信中…" : "返信を送信"}
              </button>
            </div>
            {replyError && <div className="error-banner send-error" role="alert">{replyError} 入力内容を保持しています。</div>}
          </form>
        </article>
      )}
    </main>
  );
}

function formatSentAt(value: string) {
  return new Intl.DateTimeFormat("ja-JP", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(value));
}
