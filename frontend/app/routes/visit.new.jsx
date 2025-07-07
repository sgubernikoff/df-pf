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

  const shopifyData = await fetchAllProductsFromCollection("bridal");
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

  // New state for upload progress
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState([]);

  async function uploadFileToS3(file, presignedData, index) {
    const formData = new FormData();

    // Add all the presigned fields
    Object.entries(presignedData.fields).forEach(([key, value]) => {
      formData.append(key, value);
    });
    formData.append("file", file);

    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();

      // Track upload progress
      xhr.upload.addEventListener("progress", (e) => {
        if (e.lengthComputable) {
          const percentComplete = (e.loaded / e.total) * 100;
          setUploadProgress((prev) => {
            const newProgress = [...prev];
            newProgress[index] = { name: file.name, progress: percentComplete };
            return newProgress;
          });
        }
      });

      xhr.addEventListener("load", () => {
        if (xhr.status === 201) {
          // Parse the S3 response to get ETag
          const parser = new DOMParser();
          const xmlDoc = parser.parseFromString(xhr.responseText, "text/xml");
          const etag =
            xmlDoc
              .getElementsByTagName("ETag")[0]
              ?.textContent?.replace(/"/g, "") || null;

          resolve({
            key: presignedData.filename,
            filename: file.name,
            content_type: file.type,
            byte_size: file.size,
            checksum: etag, // ETag from S3 response
            url: presignedData.final_url,
          });
        } else {
          reject(new Error(`Upload failed: ${xhr.status}`));
        }
      });

      xhr.addEventListener("error", () => reject(new Error("Upload failed")));

      xhr.open("POST", presignedData.url);
      xhr.send(formData);
    });
  }

  async function handleUploadAndSubmit(e) {
    e.preventDefault();
    const form = formRef.current;
    const fileInput = form.querySelector('input[name="visit[images][]"]');
    const files = Array.from(fileInput.files);

    if (files.length === 0) {
      // No files to upload, submit directly
      fetcher.submit(form, { method: "post", encType: "multipart/form-data" });
      return;
    }

    setUploading(true);
    setUploadProgress(files.map((f) => ({ name: f.name, progress: 0 })));
    console.log("1");
    try {
      // 1. Get presigned URLs for all files via Remix API route
      const filesInfo = files.map((file) => ({
        name: file.name,
        type: file.type,
        size: file.size,
      }));
      console.log("log2");
      const presignedResponse = await fetch("/api/upload", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ files: filesInfo }),
      });
      console.log(presignedResponse);

      if (!presignedResponse.ok) {
        const errorData = await presignedResponse.json();
        throw new Error(errorData.error || "Failed to get presigned URLs");
      }

      const { presigned_urls } = await presignedResponse.json();
      // 2. Upload all files in parallel to S3
      const uploadPromises = files.map((file, index) =>
        uploadFileToS3(file, presigned_urls[index], index)
      );

      const uploadResults = await Promise.all(uploadPromises);
      // 3. Add URLs to form and submit
      uploadResults.forEach((result) => {
        const input = document.createElement("input");
        input.type = "hidden";
        input.name = "visit[image_urls][]";
        input.value = JSON.stringify(result);
        form.appendChild(input);
      });

      // Remove file input and submit
      fileInput.remove();
      fetcher.submit(form, { method: "post", encType: "multipart/form-data" });
    } catch (error) {
      console.error("Upload failed:", error);
      alert(`Upload failed: ${error.message}. Please try again.`);
    } finally {
      setUploading(false);
      setUploadProgress([]);
    }
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
          {showManualEntry ? "Search For Client" : "Create New Client"}
        </button>

        {showManualEntry ? (
          <>
            <label>
              Client Name:
              <input
                type="text"
                name="visit[customer_name]"
                value={selectedUser?.name || userQuery}
                onChange={(e) => setUserQuery(e.target.value)}
                required
              />
            </label>
            <label>
              Client Email:
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
            accept="image/*,video/*"
            disabled={uploading}
          />
        </label>

        {/* Upload Progress */}
        {uploading && (
          <div style={{ marginBottom: "1rem" }}>
            <p>Uploading files...</p>
            {uploadProgress.map((file, index) => (
              <div key={index} style={{ marginBottom: "0.5rem" }}>
                <div style={{ fontSize: "0.9em" }}>{file.name}</div>
                <div
                  style={{
                    width: "100%",
                    backgroundColor: "#e0e0e0",
                    borderRadius: "4px",
                    height: "8px",
                  }}
                >
                  <div
                    style={{
                      width: `${file.progress}%`,
                      backgroundColor: "#4CAF50",
                      height: "100%",
                      borderRadius: "4px",
                      transition: "width 0.3s ease",
                    }}
                  />
                </div>
                <div style={{ fontSize: "0.8em", color: "#666" }}>
                  {Math.round(file.progress)}%
                </div>
              </div>
            ))}
          </div>
        )}

        <button type="submit" disabled={uploading}>
          {uploading ? "Uploading..." : "Submit Visit"}
        </button>

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
