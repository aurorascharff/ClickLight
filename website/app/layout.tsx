import type { Metadata } from "next";
import { Analytics } from "@vercel/analytics/next";
import "./globals.css";

const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ?? "https://click-light.vercel.app";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "ClickLight",
    template: "%s - ClickLight",
  },
  description:
    "A tiny macOS menu bar app that highlights your clicks during demos, screen sharing, UX reviews, and anywhere people need to follow what you are doing.",
  applicationName: "ClickLight",
  authors: [
    { name: "Aurora Scharff", url: "https://github.com/aurorascharff" },
  ],
  creator: "Aurora Scharff",
  keywords: [
    "ClickLight",
    "macOS",
    "screen sharing",
    "live demos",
    "cursor",
    "click highlights",
  ],
  icons: {
    icon: "/clicklight-icon.png",
    apple: "/clicklight-icon.png",
  },
  openGraph: {
    title: "ClickLight",
    description:
      "A tiny macOS menu bar app that makes clicks visible during demos, screen sharing, and UX reviews.",
    type: "website",
    url: siteUrl,
    siteName: "ClickLight",
  },
  twitter: {
    card: "summary_large_image",
    title: "ClickLight",
    description:
      "A tiny macOS menu bar app that makes clicks visible during demos, screen sharing, and UX reviews.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  );
}
