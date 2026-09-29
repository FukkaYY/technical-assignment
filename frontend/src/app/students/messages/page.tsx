"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiRequestError, ConversationListItem, getConversations } from "@/lib/api";

export default function StudentMessagesPage() {
  const router = useRouter();
  const [conversations, setConversations] = useState<ConversationListItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState("");
  const [retryKey, setRetryKey] = useState(0);

  useEffect(() => {
    let cancelled = false;

    void getConversations()
      .then(({ data }) => {
        if (!cancelled) setConversations(data);
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
          setError(requestError.errors[0]?.message ?? "受信メッセージの読み込みに失敗しました。");
          return;
        }
        setError("受信メッセージの読み込みに失敗しました。");
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [retryKey, router]);

  function retry() {
    setError("");
    setIsLoading(true);
    setRetryKey((current) => current + 1);
  }

  return (
    <main className="inbox-shell">
      <Link className="back-link" href="/students/me">← 学生マイページへ戻る</Link>
      <header className="inbox-header">
        <p className="eyebrow">INBOX</p>
        <h1>受信メッセージ</h1>
        <p>企業から届いたスカウトメッセージを確認できます。</p>
      </header>

      {isLoading && <section className="list-state"><p className="loading">受信メッセージを読み込んでいます…</p></section>}

      {!isLoading && error && (
        <section className="list-state error-state" role="alert">
          <p>{error}</p>
          <button className="secondary-button compact-button" type="button" onClick={retry}>再試行</button>
        </section>
      )}

      {!isLoading && !error && conversations.length === 0 && (
        <section className="list-state empty-state">
          <h2>メッセージはまだありません</h2>
          <p>企業からメッセージが届くと、ここに表示されます。</p>
        </section>
      )}

      {!isLoading && !error && conversations.length > 0 && (
        <section className="inbox-list" aria-label="受信した会話">
          {conversations.map((conversation) => (
            <Link key={conversation.id} className="inbox-item" href={`/students/messages/${conversation.id}`}>
              <div>
                <div className="inbox-item-heading">
                  <h2>{conversation.company.company_name}</h2>
                  {conversation.unread_count > 0 && (
                    <span className="unread-badge" aria-label={`未読 ${conversation.unread_count}件`}>
                      未読 {conversation.unread_count}件
                    </span>
                  )}
                  {conversation.unseen_schedule_proposal_count > 0 && (
                    <span className="unread-badge" aria-label={`新しい面談提案 ${conversation.unseen_schedule_proposal_count}件`}>
                      面談提案 {conversation.unseen_schedule_proposal_count}件
                    </span>
                  )}
                </div>
                <p>{conversation.latest_message_excerpt}</p>
              </div>
              <time dateTime={conversation.latest_activity_at}>{formatSentAt(conversation.latest_activity_at)}</time>
            </Link>
          ))}
        </section>
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
