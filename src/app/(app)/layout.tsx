import { BottomTabs } from "@/components/shell/bottom-tabs";
import { DemoBanner } from "@/components/shell/demo-banner";
import { SideRail } from "@/components/shell/side-rail";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-dvh">
      <SideRail />
      <div className="flex min-w-0 flex-1 flex-col">
        <DemoBanner />
        <main
          id="main"
          className="flex-1 px-5 pt-[max(1.5rem,env(safe-area-inset-top))] pb-[calc(5rem+env(safe-area-inset-bottom))] md:px-10 md:py-10"
        >
          {children}
        </main>
      </div>
      <BottomTabs />
    </div>
  );
}
