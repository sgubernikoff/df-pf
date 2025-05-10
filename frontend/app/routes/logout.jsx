// app/routes/logout.tsx
import { redirect } from "@remix-run/node";
import { logout } from "../utils/session.server"; // Ensure correct import path

export async function action({ request }) {
  // Perform logout logic (destroy session and redirect)
  return redirect("/", {
    headers: {
      "Set-Cookie": await logout(request), // Logout the user and destroy the session cookie
    },
  });
}
