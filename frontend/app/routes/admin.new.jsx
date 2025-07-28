import { Form, useActionData, useRouteLoaderData } from "@remix-run/react";
import { json, redirect } from "@remix-run/node";

export async function loader({ request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );
  const token = decodeURIComponent(cookies.token);
  if (!token.includes("Bearer")) return redirect("/login");

  const res = await fetch("http://localhost:3000/current_user", {
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
  const phone = form.get("phone");
  const title = form.get("title");
  const office = form.get("office");
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
      user: {
        name,
        email,
        phone,
        title,
        office,
        password,
        password_confirmation,
        is_admin,
      },
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
  console.log(data);

  const { new_admin_user_form } = useRouteLoaderData("root");
  console.log(new_admin_user_form);

  return (
    <div className="form-create-page">
      <div className="content">
        <h1>{new_admin_user_form?.form_title || "New Salesperson"}</h1>
        <Form method="post">
          <label>
            {new_admin_user_form?.name?.label || "Name"}
            <input
              name="name"
              className="sign-up-email-input"
              placeholder={new_admin_user_form?.name?.placeholder || ""}
            />
          </label>
          <label>
            {new_admin_user_form?.title?.label || "Title"}
            <input
              name="title"
              className="sign-up-email-input"
              placeholder={new_admin_user_form?.title?.placeholder || ""}
            />
          </label>
          <label>
            {new_admin_user_form?.email?.label || "Email"}
            <input
              name="email"
              className="sign-up-email-input"
              placeholder={new_admin_user_form?.email?.placeholder || ""}
            />
          </label>
          <label>
            {new_admin_user_form?.phone?.label || "Phone"}
            <input
              name="phone"
              className="sign-up-email-input"
              placeholder={
                new_admin_user_form?.phone?.placeholder || "xxx.xxx.xxxx"
              }
            />
          </label>
          <div>
            <label style={{ display: "block" }}>
              {new_admin_user_form?.office?.label || "Office"}
            </label>
            <div
              style={{
                border: "none",
                height: "44px",
                display: "flex",
                alignItems: "center",
                gap: "24px",
                marginBottom: "10px",
              }}
            >
              <label
                style={{
                  display: "flex",
                  alignItems: "flex-start",
                  gap: "8px",
                  cursor: "pointer",
                }}
              >
                <input
                  type="radio"
                  name="office"
                  value="NY"
                  style={{ accentColor: "black", cursor: "pointer" }}
                />
                New York
              </label>
              <label
                style={{
                  display: "flex",
                  alignItems: "flex-start",
                  gap: "8px",
                  cursor: "pointer",
                }}
              >
                <input
                  type="radio"
                  name="office"
                  value="LA"
                  style={{ accentColor: "black", cursor: "pointer" }}
                />
                Los Angeles
              </label>
            </div>
          </div>
          <label>
            {new_admin_user_form?.password?.label || "Password"}
            <input
              name="password"
              type="password"
              placeholder={new_admin_user_form?.password?.placeholder || ""}
            />
          </label>
          <label>
            {new_admin_user_form?.password_confirmation?.label ||
              "Password Confirmation"}
            <input
              name="password_confirmation"
              type="password"
              placeholder={
                new_admin_user_form?.password_confirmation?.placeholder || ""
              }
            />
          </label>
          <button type="submit">
            {new_admin_user_form?.submit_button?.label || "SIGN UP"}
          </button>
          {data?.errors?.name && (
            <p style={{ color: "red" }}>{`Name ${data.errors.name[0]}`}</p>
          )}
          {data?.errors?.email && (
            <p style={{ color: "red" }}>{`Email ${data.errors.email[0]}`}</p>
          )}
          {data?.errors?.phone && (
            <p style={{ color: "red" }}>{`Phone ${data.errors.phone[0]}`}</p>
          )}
          {data?.errors?.title && (
            <p style={{ color: "red" }}>{`Title ${data.errors.title[0]}`}</p>
          )}
          {data?.errors?.office && (
            <p style={{ color: "red" }}>{`Office ${data.errors.office[0]}`}</p>
          )}
          {data?.errors?.password && (
            <p style={{ color: "red" }}>
              {`Password ${data.errors.password[0]}`}
            </p>
          )}
          {data?.errors?.password_confirmation && (
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
