import { json, redirect } from "@remix-run/node";
import { useLoaderData, Form } from "@remix-run/react";
import { getUserId, logout } from "../utils/session.server"; // Import correct functions

export function meta() {
  return [
    { title: "xx" },
    { name: "description", content: "Welcome to Remix!" },
  ];
}

export async function loader({ request }) {
  const userId = await getUserId(request); // Correct function call to get user ID
  if (!userId) {
    return json({ user: null });
  }

  const res = await fetch(`http://localhost:3000/users/${userId}`);
  const user = await res.json(); // Await the fetch response
  return json({ user });
}

export async function action({ request }) {
  // const session = await getUserSession(request);
  return redirect("/", {
    headers: {
      "Set-Cookie": await logout(request), // Pass request to logout
    },
  });
}

export default function Index() {
  const { user } = useLoaderData();
  console.log(user);
  return (
    <div style={{ padding: 20 }}>
      <h1>Welcome to the app</h1>
      <p>{user ? `Logged in as ${user.name}` : "Not logged in"}</p>{" "}
      {/* Assuming `user` has a `name` property */}
      {user ? (
        <Form method="post">
          <button type="submit">Logout</button>
        </Form>
      ) : (
        <a href="/login">
          <button>Login</button>
        </a>
      )}
    </div>
  );
}
