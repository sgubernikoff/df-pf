import { Form, useActionData } from "@remix-run/react";
import { json, redirect } from "@remix-run/node";

export async function loader({ request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );
  const token = decodeURIComponent(cookies.token);
  if (!token.includes("Bearer")) return redirect("/login");

  const res = await fetch("https://df-pf.onrender.com/current_user", {
    headers: {
      Authorization: token,
      "Content-Type": "application/json",
      credentials: "include",
    },
  });
  if (!res.ok) redirect("/login");
  const current_user = await res.json();
  if (!current_user.data.is_admin)
    return redirect(`/user/${current_user.data.id}`);
  console.log(current_user);

  return json({ current_user });
}

export async function action({ request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );
  const token = decodeURIComponent(cookies.token);
  if (!token.includes("Bearer")) return redirect("/login");

  const form = await request.formData();
  const name = form.get("name");
  const email = form.get("email");
  const password = form.get("password");
  const password_confirmation = form.get("password_confirmation");
  const is_admin = true;

  // if (password !== password_confirmation)
  //   return json(
  //     { errors: ["Password and Password Confirmation must match"] },
  //     { status: 400 }
  //   );

  const res = await fetch("https://df-pf.onrender.com/users", {
    method: "POST",
    headers: {
      Authorization: token,
      "Content-Type": "application/json",
      credentials: "include",
    },
    body: JSON.stringify({
      user: { name, email, password, password_confirmation, is_admin },
    }),
  });

  if (!res.ok) {
    const errorData = await res.json();
    return json({ errors: errorData.errors }, { status: 400 });
  } else
    return json(
      { success: "Salesperson created successfully!" },
      { status: 200 }
    );
}

export default function Signup() {
  const data = useActionData();

  return (
    <div className="form-create-page">
      <div className="content">
        <h1>New Salesperson</h1>
        <Form method="post">
          <label>
            Name
            <input name="name" className="sign-up-email-input" />
          </label>
          <label>
            Email
            <input name="email" className="sign-up-email-input" />
          </label>
          <label>
            Password
            <input name="password" type="password" />
          </label>
          <label>
            Password Confirmation
            <input name="password_confirmation" type="password" />
          </label>
          <button type="submit">SIGN UP</button>
          {data?.errors.name && (
            <p style={{ color: "red" }}>{`Name ${data.errors.name[0]}`}</p>
          )}
          {data?.errors.email && (
            <p style={{ color: "red" }}>{`Email ${data.errors.email[0]}`}</p>
          )}
          {data?.errors.password && (
            <p style={{ color: "red" }}>
              {`Password ${data.errors.password[0]}`}
            </p>
          )}
          {data?.errors.password_confirmation && (
            <p style={{ color: "red" }}>
              {`Password Confirmation ${data.errors.password_confirmation[0]}`}
            </p>
          )}
          {data?.success && <p style={{ color: "green" }}>{data.success}</p>}
        </Form>
      </div>
    </div>
  );
}
