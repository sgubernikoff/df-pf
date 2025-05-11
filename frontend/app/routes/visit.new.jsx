import { useFetcher, useLoaderData } from "@remix-run/react";
import { useEffect, useState } from "react";
import { json, redirect } from "@remix-run/node";
import { fetchAllProductsFromCollection } from "../utils/shopifyClient.server";

// --- 1. Loader: Fetch dresses ---
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

  const shopifyData = await fetchAllProductsFromCollection("new-arrivals");
  console.log(shopifyData);

  const res = await fetch("http://localhost:3000/dresses", {
    headers: {
      Authorization: token,
      "Content-Type": "application/json",
    },
  });

  if (!res.ok) redirect("/login");
  const dresses = await res.json();
  return json({ dresses, shopifyData });
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
  const { dresses, shopifyData } = useLoaderData();
  const fetcher = useFetcher();

  const [selectedDress, setSelectedDress] = useState(null);
  const [dressQuery, setDressQuery] = useState("");
  const [dressIds, setDressIds] = useState([]);

  const [userQuery, setUserQuery] = useState("");
  const [userResults, setUserResults] = useState([]);
  const [selectedUser, setSelectedUser] = useState(null);

  useEffect(() => {
    if (userQuery.length < 2 || selectedUser) return;

    const fetchUsers = async () => {
      const res = await fetch(
        `/user-search?query=${encodeURIComponent(userQuery)}`
      );
      if (res.ok) {
        const { data } = await res.json();
        setUserResults(data.map((d) => d.attributes));
      }
    };

    const timeout = setTimeout(fetchUsers, 200); // debounce
    return () => clearTimeout(timeout);
  }, [userQuery, selectedUser]);

  const handleDressSelection = (e) => {
    const value = e.target.value;
    setDressIds((prev) =>
      prev.includes(value)
        ? prev.filter((id) => id !== value)
        : [...prev, value]
    );
  };

  const filtered =
    dressQuery.length > 0
      ? shopifyData.filter((d) =>
          d.title.toLowerCase().includes(dressQuery.toLowerCase())
        )
      : [];

  return (
    <fetcher.Form method="post" encType="multipart/form-data">
      <h2>New Visit</h2>

      <label>
        Search for User:
        <input
          type="text"
          value={userQuery}
          onChange={(e) => {
            setUserQuery(e.target.value);
            setSelectedUser(null);
          }}
          placeholder="Start typing a name..."
          autoComplete="off"
        />
      </label>
      <br />

      {userResults.length > 0 && !selectedUser && (
        <ul style={{ border: "1px solid #ccc", marginTop: 4, padding: 4 }}>
          {userResults.map((user) => (
            <li
              key={user.id}
              style={{ cursor: "pointer", padding: 4 }}
              onClick={() => {
                setSelectedUser(user);
                setUserQuery(user.name);
              }}
            >
              {user.name} — {user.email}
            </li>
          ))}
        </ul>
      )}

      {selectedUser && (
        <>
          <input type="hidden" name="visit[user_id]" value={selectedUser.id} />
          <p>
            <strong>Selected User:</strong> {selectedUser.name} (
            {selectedUser.email})
          </p>
        </>
      )}

      <label>
        Customer Name:
        <input
          type="text"
          name="visit[customer_name]"
          value={selectedUser?.name || userQuery}
          onChange={(e) => setUserQuery(e.target.value)}
          required
        />
      </label>
      <br />

      <label>
        Customer Email:
        <input
          type="email"
          name="visit[customer_email]"
          value={selectedUser?.email || ""}
          onChange={() => {}}
          readOnly={!!selectedUser}
        />
      </label>
      <br />

      <label>
        Notes:
        <textarea name="visit[notes]" />
      </label>
      <br />

      <fieldset>
        <legend>Select A Dress</legend>
        <div>
          <label htmlFor="dress">Select a dress:</label>
          <input
            id="dress"
            type="text"
            value={dressQuery}
            onChange={(e) => {
              setDressQuery(e.target.value);
              setSelectedDress(null);
            }}
            placeholder="Start typing..."
            autoComplete="off"
          />

          {filtered.length > 0 && !selectedDress && (
            <ul style={{ border: "1px solid #ccc", marginTop: 4, padding: 4 }}>
              {filtered.map((dress) => (
                <li
                  key={dress.id}
                  style={{ cursor: "pointer", padding: 4 }}
                  onClick={() => {
                    setSelectedDress(dress);
                    setDressQuery(dress.title);
                  }}
                >
                  {dress.title} — ${Number(dress.price).toFixed(2)}{" "}
                  {dress.currency}
                </li>
              ))}
            </ul>
          )}

          {selectedDress && (
            <>
              <input
                type="hidden"
                name="visit[selected_dress]"
                value={JSON.stringify(selectedDress)}
              />
              <div style={{ marginTop: 8 }}>
                <strong>Selected:</strong> {selectedDress?.title}
                <br />
                <img
                  src={selectedDress?.images?.[0]}
                  alt={selectedDress?.title}
                  width={100}
                />
              </div>
            </>
          )}
        </div>
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
