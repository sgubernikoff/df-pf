import { createClient } from "@sanity/client";

export const client = createClient({
  projectId: "407f3o4y",
  dataset: "production",
  useCdn: true, // set to `false` to bypass the edge cache
  apiVersion: "2024-01-01",
});
