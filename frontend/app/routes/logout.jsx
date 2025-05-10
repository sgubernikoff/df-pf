// app/routes/logout.tsx
import { redirect } from "@remix-run/node";
import { logout, sessionStorage } from "../utils/session.server.js";

export async function action({ request }) {
  return redirect("/", {
    headers: {
      "Set-Cookie": await logout(request),
    },
  });
}
