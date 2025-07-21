import { json, redirect } from "@remix-run/node";

export async function action({ request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );

  const token = decodeURIComponent(cookies.token);
  const isAdmin = cookies.isAdmin;

  if (!token.includes("Bearer")) {
    // redirect to login or return null
    return redirect("/login");
  }

  if (isAdmin !== "true") {
    return redirect("/");
  }

  const formData = await request.formData();
  const visitId = formData.get("visitId");
  console.log(visitId);
  const res = await fetch(
    `http://localhost:3000/visits/${visitId}/resend_email`,
    {
      method: "POST",
      headers: {
        Authorization: token,
      },
    }
  );

  if (!res.ok) {
    const error = await res.json();
    return json(
      { error: error.error || "Unknown error" },
      { status: res.status }
    );
  }

  return json({ message: "Email has been queued" });
}
