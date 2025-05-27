// app/routes/api/uploads.jsx
import { createUploadHandler } from "@vercel/blob";

export const action = async ({ request }) => {
  const handler = createUploadHandler();
  const url = await handler(request);
  return new Response(JSON.stringify({ url }), {
    headers: { "Content-Type": "application/json" },
  });
};
