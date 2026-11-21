import type { Metadata } from "next";
import { Gallery } from "./gallery";

export const metadata: Metadata = { title: "UI gallery", robots: { index: false } };

export default function UiGalleryPage() {
  return <Gallery />;
}
