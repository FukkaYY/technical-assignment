import Link from "next/link";

export default function Home() {
  return (
    <main className="shell">
      <section className="card home-card">
        <p className="eyebrow">INTERN SCOUT</p>
        <h1>あなたの可能性と、企業をつなぐ。</h1>
        <p>プロフィールを登録して、インターンのスカウトを受け取りましょう。</p>
        <nav className="home-actions" aria-label="ログインへの入口">
          <Link className="primary-link" href="/students/login">学生の方はこちら</Link>
          <Link className="home-company-link" href="/companies/login">企業の方はこちら</Link>
        </nav>
      </section>
    </main>
  );
}
