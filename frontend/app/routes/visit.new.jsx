import { useFetcher, useLoaderData } from "@remix-run/react";
import { useState } from "react";
import { json, redirect } from "@remix-run/node";
import { fetchAllProductsFromCollection } from "../utils/shopifyClient.server";
import DressAutocomplete from "../components/autocomplete/DressAutocomplete";
import UserAutocomplete from "../components/autocomplete/UserAutocomplete";

// --- 1. Loader: Fetch dresses ---
export async function loader({ request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );

  const token = decodeURIComponent(cookies.token);

  if (!token.includes("Bearer")) {
    // redirect to login or return null
    return redirect("/login");
  }

  const shopifyData = await fetchAllProductsFromCollection("new-arrivals");

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
  return json({ shopifyData });
}

// --- 2. Action: Handle form submission ---
export async function action({ request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );

  const token = decodeURIComponent(cookies.token);
  const formData = await request.formData();

  if (formData.get("price-override")) {
    const parsedDress = JSON.parse(formData.get("visit[selected_dress]"));
    parsedDress.price = `$${formatNumberInput(formData.get("price-override"))}`;
    formData.set("visit[selected_dress]", JSON.stringify(parsedDress));
  }

  formData.delete("price-override");

  const res = await fetch("http://localhost:3000//visits", {
    method: "POST",
    body: formData,
    headers: { Authorization: token },
  });

  if (!res.ok) {
    return json({ error: "Failed to create visit" }, { status: 400 });
  }

  const data = await res.json();

  return json({ success: true, visit: data });
}

// --- 3. Component ---

export default function NewVisit() {
  const { shopifyData } = useLoaderData();
  const fetcher = useFetcher();

  const [userQuery, setUserQuery] = useState("");
  const [email, setEmail] = useState("");
  const [selectedUser, setSelectedUser] = useState(null);
  const [selectedDress, setSelectedDress] = useState(null);

  const [showManualEntry, setShowManualEntry] = useState(false);

  return (
    <div className="form-create-page">
      <fetcher.Form method="post" encType="multipart/form-data">
        <h2>New Visit</h2>

        <button
          type="button"
          onClick={() => setShowManualEntry((prev) => !prev)}
        >
          {showManualEntry ? "Search For User" : "Create New User"}
        </button>

        {showManualEntry ? (
          <>
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

            <label>
              Customer Email:
              <input
                type="email"
                name="visit[customer_email]"
                value={selectedUser?.email || email}
                readOnly={selectedUser}
                onChange={(e) => {
                  setEmail(e.target.value);
                }}
              />
            </label>
          </>
        ) : (
          <UserAutocomplete
            userQuery={userQuery}
            setUserQuery={setUserQuery}
            selectedUser={selectedUser}
            setSelectedUser={setSelectedUser}
          />
        )}

        <label>
          Notes:
          <textarea name="visit[notes]" />
        </label>

        <DressAutocomplete
          shopifyData={shopifyData}
          selectedDress={selectedDress}
          setSelectedDress={setSelectedDress}
        />
        <label>
          Dress Price Override:
          <input
            name="price-override"
            type="number"
            placeholder="use to manually enter dress price, default: from shopify"
            step="any"
          />
        </label>

        <label>
          Upload Images:
          <input
            style={{ padding: "0", marginTop: "1rem", marginBottom: ".5rem" }}
            type="file"
            name="visit[images][]"
            multiple
          />
        </label>

        <button type="submit">Submit Visit</button>

        {fetcher.data?.success && (
          <p>
            Visit created. {""}
            <a href={`/user/${fetcher.data.visit.user_id}`}>View User</a>
          </p>
        )}
        {fetcher.data?.error && <p>❌ {fetcher.data.error}</p>}
      </fetcher.Form>
    </div>
  );
}

function formatNumberInput(value) {
  if (value === "" || value === null || isNaN(value)) return "";

  const num = parseFloat(value);
  const hasDecimal = value.includes(".");

  const rounded = hasDecimal ? num.toFixed(2) : Math.round(num).toString();

  // Add commas
  const [whole, decimal] = rounded.split(".");
  const withCommas = Number(whole).toLocaleString();

  return decimal ? `${withCommas}.${decimal}` : withCommas;
}
