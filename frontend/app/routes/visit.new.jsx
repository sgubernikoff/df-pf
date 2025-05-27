import { useFetcher, useLoaderData } from "@remix-run/react";
import { useRef, useState } from "react";
import { json, redirect } from "@remix-run/node";
import { fetchAllProductsFromCollection } from "../utils/shopifyClient.server";
import DressAutocomplete from "../components/autocomplete/DressAutocomplete";
import UserAutocomplete from "../components/autocomplete/UserAutocomplete";

export async function loader({ request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );
  const token = decodeURIComponent(cookies.token);
  if (!token.includes("Bearer")) return redirect("/login");

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

export async function action({ request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );
  const token = decodeURIComponent(cookies.token);
  const formData = await request.formData();

  let parsedDress = {};
  const selectedDressStr = formData.get("visit[selected_dress]");
  if (selectedDressStr) {
    try {
      parsedDress = JSON.parse(selectedDressStr);
    } catch (e) {
      console.error("⚠️ Invalid JSON in visit[selected_dress]", e);
    }
  }
  if (formData.get("price-override")) {
    parsedDress.price = `$${formatNumberInput(formData.get("price-override"))}`;
  }
  formData.set("visit[selected_dress]", JSON.stringify(parsedDress));
  formData.delete("price-override");

  const res = await fetch("https://df-pf.onrender.com/visits", {
    method: "POST",
    body: formData,
    headers: { Authorization: token },
  });

  if (!res.ok)
    return json({ error: "Failed to create visit" }, { status: 400 });
  const data = await res.json();
  return json({ success: true, visit: data });
}

export default function NewVisit() {
  const { shopifyData } = useLoaderData();
  const fetcher = useFetcher();
  const formRef = useRef();
  const [userQuery, setUserQuery] = useState("");
  const [email, setEmail] = useState("");
  const [selectedUser, setSelectedUser] = useState(null);
  const [selectedDress, setSelectedDress] = useState(null);
  const [showManualEntry, setShowManualEntry] = useState(false);

  async function handleUploadAndSubmit(e) {
    e.preventDefault();
    const form = formRef.current;
    const fileInput = form.querySelector('input[name="visit[images][]"]');
    const files = Array.from(fileInput.files);
    const imageUrls = [];

    for (const file of files) {
      const uploadForm = new FormData();
      uploadForm.append("file", file);
      const res = await fetch("/api/uploads", {
        method: "POST",
        body: uploadForm,
      });
      const { url } = await res.json();
      imageUrls.push(url);

      const input = document.createElement("input");
      input.type = "hidden";
      input.name = "visit[image_urls][]";
      input.value = url;
      form.appendChild(input);
    }

    fileInput.remove();
    fetcher.submit(form, { method: "post", encType: "multipart/form-data" });
  }

  return (
    <div className="form-create-page">
      <fetcher.Form
        ref={formRef}
        method="post"
        encType="multipart/form-data"
        onSubmit={handleUploadAndSubmit}
      >
        <h2>New Visit</h2>
        <button
          type="button"
          onClick={() => setShowManualEntry(!showManualEntry)}
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
                onChange={(e) => setEmail(e.target.value)}
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
          Dress Price Override (OPTIONAL):
          <input
            name="price-override"
            type="number"
            placeholder="Optional — uses Shopify price if left blank"
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
            Visit created.{" "}
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
  const hasDecimal = value.toString().includes(".");
  const rounded = hasDecimal ? num.toFixed(2) : Math.round(num).toString();
  const [whole, decimal] = rounded.split(".");
  const withCommas = Number(whole).toLocaleString();
  return decimal ? `${withCommas}.${decimal}` : withCommas;
}
