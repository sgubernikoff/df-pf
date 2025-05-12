import { json, redirect } from "@remix-run/node";

export async function loader({ request }) {
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
  const url = new URL(request.url);
  const query = url.searchParams.get("query") || "";

  const res = await fetch(
    `https://df-pf.vercel.app/users/search?query=${query}`,
    {
      headers: {
        Authorization: token,
      },
    }
  );

  if (!res.ok) {
    return json([], { status: res.status });
  }

  const users = await res.json();
  return json(users);
}
