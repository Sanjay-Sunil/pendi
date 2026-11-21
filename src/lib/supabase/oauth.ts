export const GOOGLE_SCOPES = "openid email profile https://www.googleapis.com/auth/calendar";

/** Offline access + consent so Google returns a refresh token for Calendar sync. */
export const GOOGLE_QUERY_PARAMS = { access_type: "offline", prompt: "consent" } as const;
