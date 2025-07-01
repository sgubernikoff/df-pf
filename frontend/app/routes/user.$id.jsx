import { Link, redirect, useLoaderData, useFetcher } from "@remix-run/react";
import { useRef, useState, useEffect } from "react";
import { enrichUserWithShopifyVisitProducts } from "../utils/shopifyClient.server";
export async function loader({ params, request }) {
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
  // Here, you'll dynamically generate the URL to the PDF based on the visit ID.
  const res = await fetch(`https://df-pf.onrender.com/users/${params.id}`, {
    headers: {
      Authorization: token,
    },
  });
  if (!res.ok) {
    return redirect("/login");
  }
  const { data } = await res.json();
  if (data.attributes.id != params.id)
    return redirect(`/user/${data.attributes.id}`);

  const enriched = await enrichUserWithShopifyVisitProducts(data);
  return enriched;
}

export default function Visit() {
  const { attributes } = useLoaderData();

  return (
    <div className="user-page">
      <div className="client-name-container">
        <p>{attributes.name}</p>
        <p>{attributes.email}</p>
      </div>
      <div className="user-visits-container">
        {attributes.visits?.data?.map((v) => {
          return (
            <VisitGridItem
              key={v.attributes?.shopify_dress_id || "missing"}
              v={v}
            />
          );
        })}
      </div>
    </div>
  );
}

function VisitGridItem({ v }) {
  const isProcessing = !v?.attributes?.processed;
  const product = v.attributes?.product || {};
  return (
    <div className="user-dress-container">
      <Link
        style={{ textDecoration: "none" }}
        to={`/visit/${v.attributes?.id}`}
        onClick={(e) => {
          // if (isProcessing) e.preventDefault();
        }}
      >
        <div className="dress-info">
          <p className="dress-name">
            {product.title || "missing shopify data"}
          </p>
          <p className="dress-price">{v.attributes.price}</p>
        </div>
        <div
          className={`hover-scale-wrapper dress-image-wrapper${
            isProcessing ? " processing" : ""
          }`}
        >
          {product.imageUrl ? (
            <img
              className="dress-image"
              src={`${product.imageUrl}&width=333`}
              alt={product.title || "No title"}
            />
          ) : (
            <div>Image not available</div>
          )}
          {isProcessing && (
            <div className="processing-overlay">
              <p>PROCESSING</p>
            </div>
          )}
        </div>
      </Link>
      {!isProcessing && <ResendEmailButton visitId={v.attributes?.id} />}
    </div>
  );
}

export function ResendEmailButton({ visitId }) {
  const fetcher = useFetcher();

  return (
    <fetcher.Form method="post" action="/resend-email">
      <input type="hidden" name="visitId" value={visitId} />
      <button type="submit" disabled={fetcher.state !== "idle"}>
        {fetcher.state === "submitting" ? "Sending..." : "Resend Email"}
      </button>
      {fetcher.data?.error && (
        <p style={{ color: "red" }}>{fetcher.data.error}</p>
      )}
      {fetcher.data?.message && (
        <p style={{ color: "green" }}>{fetcher.data.message}</p>
      )}
    </fetcher.Form>
  );
}
