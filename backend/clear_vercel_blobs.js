const fetch = require("node-fetch");

const BLOB_STORE_ID = process.env.BLOB_STORE_ID;
const TOKEN = process.env.VERCEL_TOKEN;

if (!BLOB_STORE_ID || !TOKEN) {
  throw new Error("Missing BLOB_STORE_ID or VERCEL_TOKEN env vars.");
}

async function listBlobs(cursor = "") {
  const url = `https://blob.vercel-storage.com/api/v1/blobs?storeId=${BLOB_STORE_ID}${
    cursor ? `&cursor=${cursor}` : ""
  }`;
  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${TOKEN}`,
    },
  });
  if (!res.ok) {
    throw new Error(`Failed to list blobs: ${res.statusText}`);
  }
  return res.json();
}

async function deleteBlob(blobUrl) {
  const res = await fetch(blobUrl, {
    method: "DELETE",
    headers: {
      Authorization: `Bearer ${TOKEN}`,
    },
  });
  if (!res.ok) {
    console.error(`Failed to delete ${blobUrl}: ${res.statusText}`);
  } else {
    console.log(`✅ Deleted ${blobUrl}`);
  }
}

(async () => {
  try {
    let hasMore = true;
    let cursor = "";
    while (hasMore) {
      const data = await listBlobs(cursor);
      for (const blob of data.blobs) {
        await deleteBlob(blob.url);
      }
      hasMore = data.cursor !== undefined;
      cursor = data.cursor || "";
    }
    console.log("🎉 All blobs deleted!");
  } catch (err) {
    console.error("❌ Error:", err);
  }
})();
