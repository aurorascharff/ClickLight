import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ClickLight",
  description: "A tiny macOS app that makes clicks visible during live demos.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
