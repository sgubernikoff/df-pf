import { json, redirect } from "@remix-run/node";
import { useLoaderData, Form } from "@remix-run/react";
import { getUserId, logout } from "../utils/session.server";
import "../styles/app.css"; // Import your styles
import logo from "../styles/DanielleFrankelMainLogo.jpg";

export function meta() {
  return [
    { title: "Danielle Frankel Client Visit Dashboard" },
    { name: "description", content: "Welcome to Remix!" },
  ];
}

export async function loader({ request }) {
  const userId = await getUserId(request);
  if (!userId) {
    return json({ user: null });
  }

  const res = await fetch(`http://localhost:3000/users/${userId}`);
  const user = await res.json();
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
