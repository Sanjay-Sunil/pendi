// Tests must not depend on the developer machine's timezone or env.
process.env.TZ = "UTC";
process.env.APP_TIMEZONE = "Asia/Kolkata";

if (process.env.LIVE_NETWORK !== "1") {
  console.info("[daybook] live-network tests skipped; run with LIVE_NETWORK=1 to include them");
}
