import { json } from "@remix-run/node";

export async function action({ request }) {
  // Reuse your existing auth logic
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );
  const token = decodeURIComponent(cookies.token);

  if (!token.includes("Bearer")) {
    return json({ error: "Unauthorized" }, { status: 401 });
  }

  // Verify user is authenticated
  const userRes = await fetch(
    "https://daniellefrankelphotos.com/current_user",
    {
      headers: {
        Authorization: token,
        "Content-Type": "application/json",
      },
    }
  );

  if (!userRes.ok) {
    return json({ error: "Unauthorized" }, { status: 401 });
  }

  // Forward the request to your Rails API
  const body = await request.json();
  const uploadRes = await fetch("https://daniellefrankelphotos.com/upload", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: token,
    },
    body: JSON.stringify(body),
  });

  if (!uploadRes.ok) {
    return json({ error: "Upload failed" }, { status: uploadRes.status });
  }
  return json(await uploadRes.json());
}
