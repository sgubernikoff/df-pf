import { json, redirect } from "@remix-run/node";
import { Form, useActionData, Link } from "@remix-run/react";
import { useState } from "react";
import { getUserSession, sessionStorage } from "../utils/session.server";
import "../styles/app.css"; // Link to the CSS file

export async function action({ request }) {
  const form = await request.formData();
  const email = form.get("email");
  const password = form.get("password");

  const res = await fetch("http://localhost:3000/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const errorData = await res.json();
    return json({ errors: errorData.errors }, { status: 401 });
  }

  const user = await res.json();
  const session = await getUserSession(request);
  session.set("userId", user.id);

  return redirect("/", {
    headers: {
      "Set-Cookie": await sessionStorage.commitSession(session),
    },
  });
}

export default function Login() {
  const actionData = useActionData();
  const [isLoading, setIsLoading] = useState(false);

  return (
    <div className="container">
      <div className="content">
        <p>Log In</p>
        <Form method="post">
          <label>
            Email
            <input type="text" name="email" />
          </label>
          <label>
            Password
            <input type="password" name="password" />
          </label>
          <button type="submit" onClick={() => setIsLoading(true)}>
            {isLoading ? "LOGGING IN..." : "LOG IN"}
          </button>
          {actionData?.errors?.map((e) => (
            <p key={e} style={{ color: "red" }}>
              {e}
            </p>
          ))}
        </Form>
        <p style={{ marginTop: "1rem" }}>
          Don't have an account?{" "}
          <Link to="/signup" style={{ textDecoration: "underline" }}>
            Sign up here
          </Link>
        </p>
      </div>
    </div>
  );
}
