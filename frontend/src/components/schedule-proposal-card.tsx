import { ScheduleProposal } from "@/lib/api";

const STATUS_LABELS: Record<ScheduleProposal["status"], string> = {
  pending: "回答待ち",
  accepted: "承諾",
  declined: "辞退",
  cancelled: "取消",
};

export default function ScheduleProposalCard({ proposal, actions }: { proposal: ScheduleProposal; actions?: React.ReactNode }) {
  return (
    <article className="schedule-card">
      <div className="schedule-card-heading">
        <h3>{formatDateTime(proposal.starts_at)}〜{formatTime(proposal.ends_at)}</h3>
        <span className={`schedule-status ${proposal.status}`}>{STATUS_LABELS[proposal.status]}</span>
      </div>
      <dl>
        <div><dt>実施方法・場所</dt><dd>{proposal.location}</dd></div>
        {proposal.note && <div><dt>補足</dt><dd>{proposal.note}</dd></div>}
      </dl>
      {actions}
    </article>
  );
}

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat("ja-JP", { dateStyle: "medium", timeStyle: "short", timeZone: "Asia/Tokyo" }).format(new Date(value));
}

function formatTime(value: string) {
  return new Intl.DateTimeFormat("ja-JP", { hour: "2-digit", minute: "2-digit", timeZone: "Asia/Tokyo" }).format(new Date(value));
}
