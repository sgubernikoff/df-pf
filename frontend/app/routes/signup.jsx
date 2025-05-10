// app/routes/signup.tsx
import { Form, useActionData } from "@remix-run/react";
import { json, redirect } from "@remix-run/node";

export async function action({ request }) {
  const form = await request.formData();
  const email = form.get("email");
  const password = form.get("password");

  const res = await fetch("http://localhost:3000/users", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const errorData = await res.json();
    return json({ errors: errorData.errors }, { status: 400 });
  }

  return redirect("/login");
}

export default function Signup() {
  const data = useActionData();

  return (
    <Form method="post">
      <label>
        Email
        <input name="email" />
      </label>
      <label>
        Password
        <input name="password" type="password" />
      </label>
      <button type="submit">Sign up</button>
      {data?.errors?.map((e) => (
        <p key={e} style={{ color: "red" }}>
          {e}
        </p>
      ))}
    </Form>
  );
}
