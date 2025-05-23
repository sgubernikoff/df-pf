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
      <p>Dresses</p>
      <div
        className="user-visits-container"
        style={{
          display: "grid",
          gap: "1vw",
          gridTemplateColumns: "repeat(auto-fit, minmax(300px, 0fr))",
          gridTemplateRows: "min-content",
        }}
      >
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
  return (
    <div className="user-dress-container">
      <Link
        to={`/visit/${v.attributes?.id}`}
        style={{
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center",
          border: "1px solid #e9e9e9",
          position: "relative",
          cursor: !v.attributes?.isPdfReady ? "not-allowed" : "",
          pointerEvents: !v.attributes?.isPdfReady ? "none" : "",
          padding: "1rem",
        }}
        onClick={(e) => {
          if (!v.attributes?.isPdfReady) e.preventDefault();
        }}
        // className="user-dress-container"
      >
        {v.attributes?.product?.imageUrl ? (
          <img
            style={{ width: "100%" }}
            src={`${v?.attributes?.product?.imageUrl}&width=333`}
            alt={v.attributes.product.title || "No title"}
          />
        ) : (
          <div>Image not available</div>
        )}
        <span>{v.attributes?.product?.title || "missing shopify data"}</span>
        {!v?.attributes?.isPdfReady && (
          <div
            style={{
              position: "absolute",
              background: "black",
              opacity: 0.25,
              inset: 0,
              zIndex: 2,
            }}
          >
            <p
              style={{
                position: "absolute",
                top: "50%",
                left: "50%",
                transform: "translate(-50%,-50%) rotate(45deg)",
                fontSize: "24px",
                color: "white",
              }}
            >
              PROCESSING
            </p>
          </div>
        )}
      </Link>
      {v.attributes?.isPdfReady && (
        <ResendEmailButton visitId={v.attributes?.id} />
      )}
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
