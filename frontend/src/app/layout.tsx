import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Intern Scout",
  description: "インターン生と企業をつなぐスカウトサービス",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="ja">
      <body>{children}</body>
    </html>
  );
}
