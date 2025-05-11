import { useLoaderData, useFetcher, redirect } from "@remix-run/react";
import { json } from "@remix-run/node";
import { useState } from "react";
import axios from "axios";
import Cookies from "js-cookie";

// --- 1. Loader: Fetch dresses ---
export async function loader({ request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );

  const token = decodeURIComponent(cookies.token);
  const isAdmin = cookies.isAdmin;
  console.log("xxxx", token, cookies);
  if (!token.includes("Bearer")) {
    // redirect to login or return null
    return redirect("/login");
  }

  if (isAdmin !== "true") {
    return redirect("/");
  }

  const res = await fetch("http://localhost:3000/dresses", {
    headers: {
      Authorization: token,
      "Content-Type": "application/json",
    },
  });

  if (!res.ok) redirect("/login");
  const dresses = await res.json();
  return json({ dresses });
}

// --- 2. Action: Handle form submission ---
export async function action({ request }) {
  const formData = await request.formData();

  const res = await fetch("http://localhost:3000/visits", {
    method: "POST",
    body: formData,
  });

  if (!res.ok) {
    return json({ error: "Failed to create visit" }, { status: 400 });
  }

  const data = await res.json();
  return json({ success: true, visit: data });
}

// --- 3. Component ---
export default function NewVisit() {
  const { dresses } = useLoaderData();
  const fetcher = useFetcher();

  const [dressIds, setDressIds] = useState([]);

  const handleDressSelection = (e) => {
    const value = e.target.value;
    setDressIds((prev) =>
      prev.includes(value)
        ? prev.filter((id) => id !== value)
        : [...prev, value]
    );
  };

  return (
    <fetcher.Form method="post" encType="multipart/form-data">
      <h2>New Visit</h2>

      <label>
        Customer Name:
        <input type="text" name="visit[customer_name]" required />
      </label>
      <br />

      <label>
        Customer Email:
        <input type="email" name="visit[customer_email]" />
      </label>
      <br />

      <label>
        Notes:
        <textarea name="visit[notes]" />
      </label>
      <br />

      <fieldset>
        <legend>Select Dresses</legend>
        {dresses.map((dress) => (
          <label key={dress.id}>
            <input
              type="checkbox"
              value={dress.id}
              name="visit[dress_ids][]"
              checked={dressIds.includes(String(dress.id))}
              onChange={handleDressSelection}
            />
            {dress.name}
          </label>
        ))}
      </fieldset>
      <br />

      <label>
        Upload Images:
        <input type="file" name="visit[images][]" multiple />
      </label>
      <br />

      <button type="submit">Submit Visit</button>

      {fetcher.data?.success && (
        <p>
          ✅ Visit created successfully!{" "}
          <a href={`/visit/${fetcher.data.visit.id}`}>View Visit</a>
        </p>
      )}
      {fetcher.data?.error && <p>❌ {fetcher.data.error}</p>}
    </fetcher.Form>
  );
}
