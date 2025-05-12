import { json, redirect } from "@remix-run/node";
import { useLoaderData } from "@remix-run/react";
import { logout } from "../utils/session.server";
import "../styles/app.css"; // Import your styles

export function meta() {
  return [
    { title: "Danielle Frankel Client Visit Dashboard" },
    { name: "description", content: "Welcome to Remix!" },
  ];
}

export async function loader({ request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );

  const token = decodeURIComponent(cookies.token);

  if (!token.includes("Bearer")) {
    // redirect to login or return null
    return redirect("/login");
  }

  const res = await fetch("${process.env.RAILS_API_URL}/current_user", {
    headers: {
      Authorization: token,
      "Content-Type": "application/json",
    },
  });

  if (!res.ok) redirect("/login");
  const current_user = await res.json();
  if (!current_user.data.is_admin)
    return redirect(`/user/${current_user.data.id}`);

  return json({ user });
}

export async function action({ request }) {
  return redirect("/", {
    headers: {
      "Set-Cookie": await logout(request),
    },
  });
}

export default function Index() {
  const { user } = useLoaderData();

  return (
    <div className="container">
      <main>
        {user ? (
          <form>
            <label>
              Example Field:
              <input type="text" name="example" />
            </label>
            <button type="submit">Submit</button>
          </form>
        ) : null}
      </main>
    </div>
  );
}
