"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ApiRequestError, CompanyConversationListItem, getCompanyConversations } from "@/lib/api";

export default function CompanyMessagesPage() {
  const router = useRouter();
  const [conversations, setConversations] = useState<CompanyConversationListItem[]>([]);
  const [error, setError] = useState("");
  const [isLoading, setIsLoading] = useState(true);
  const [retryKey, setRetryKey] = useState(0);

  useEffect(() => {
    let cancelled = false;
    void getCompanyConversations()
      .then(({ data }) => { if (!cancelled) setConversations(data); })
      .catch((requestError: unknown) => {
        if (cancelled) return;
        if (requestError instanceof ApiRequestError) {
          if (requestError.errors.some((item) => item.code === "unauthenticated")) return router.replace("/companies/login");
          if (requestError.errors.some((item) => item.code === "forbidden")) return router.replace("/students/me");
          setError(requestError.errors[0]?.message ?? "メッセージ一覧の読み込みに失敗しました。");
          return;
        }
        setError("メッセージ一覧の読み込みに失敗しました。");
      })
      .finally(() => { if (!cancelled) setIsLoading(false); });
    return () => { cancelled = true; };
  }, [retryKey, router]);

  function retry() {
    setError("");
    setIsLoading(true);
    setRetryKey((current) => current + 1);
  }

  return (
    <main className="inbox-shell">
      <Link className="back-link" href="/students">← 学生一覧へ戻る</Link>
      <header className="inbox-header">
        <p className="eyebrow">MESSAGES</p>
        <h1>メッセージ一覧</h1>
        <p>学生との過去のやり取りを確認できます。</p>
      </header>

      {isLoading && <section className="list-state"><p className="loading">メッセージ一覧を読み込んでいます…</p></section>}
      {!isLoading && error && <section className="list-state error-state" role="alert"><p>{error}</p><button className="secondary-button compact-button" type="button" onClick={retry}>再試行</button></section>}
      {!isLoading && !error && conversations.length === 0 && <section className="list-state empty-state"><h2>送信済みメッセージはありません</h2><p>学生へメッセージを送信すると、ここに会話が表示されます。</p></section>}
      {!isLoading && !error && conversations.length > 0 && (
        <section className="inbox-list" aria-label="学生との会話">
          {conversations.map((conversation) => (
            <Link className="inbox-item" href={`/students/${conversation.student.id}/messages`} key={conversation.id}>
              <div>
                <div className="inbox-item-heading"><h2>{conversation.student.name}</h2><span className="message-sender-label">{conversation.latest_sender_role === "company" ? "自社から送信" : "学生から返信"}</span></div>
                <p>{conversation.latest_message_excerpt}</p>
              </div>
              <time dateTime={conversation.latest_message_sent_at}>{formatSentAt(conversation.latest_message_sent_at)}</time>
            </Link>
          ))}
        </section>
      )}
    </main>
  );
}

function formatSentAt(value: string) {
  return new Intl.DateTimeFormat("ja-JP", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value));
}
