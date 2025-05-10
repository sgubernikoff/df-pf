// app/utils/session.server.ts
import { createCookieSessionStorage } from "@remix-run/node";

export const sessionStorage = createCookieSessionStorage({
  cookie: {
    name: "user_session",
    secrets: [process.env.SESSION_SECRET || "your-secret-here"], // ⚠️ replace with env var in prod
    sameSite: "lax",
    path: "/",
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
  },
});

export async function getUserSession(request) {
  return sessionStorage.getSession(request.headers.get("Cookie"));
}

export async function getUserId(request) {
  const session = await getUserSession(request);
  return session.get("userId");
}

export async function requireUser(request) {
  const user = await getUserId(request);
  if (!user) {
    throw new Response("Unauthorized", { status: 401 });
  }
  return user;
}

export async function logout(request) {
  const session = await getUserSession(request);
  return sessionStorage.destroySession(session);
}
