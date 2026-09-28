// Supabase public (anon) config. The anon key is meant to be public;
// data is protected by Row Level Security in supabase/setup.sql.
window.APP_CONFIG = {
  SUPABASE_URL: "https://zmuuzzpbvunuejkitpfo.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptdXV6enBidnVudWVqa2l0cGZvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1NjA0NTYsImV4cCI6MjEwNjEzNjQ1Nn0.VnrJlrEItuJwc0rdQymzyFA6NZQgnCsAbMPXDRcccNQ",
  BUCKET: "flood-evidence",
  TABLE: "flood_leave_requests",
  // HR signs in with password only; this is the Supabase Auth account it uses.
  HR_EMAIL: "hr-admin@flood-leave.app"
};
