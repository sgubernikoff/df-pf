import { Link, redirect, useLoaderData } from "@remix-run/react";
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
  const res = await fetch(`http://localhost:3000/users/${params.id}`, {
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

  console.log(attributes);
  return (
    <div>
      <p style={{ fontSize: "36px" }}>{attributes.name}</p>
      <p style={{ fontSize: "24px" }}>{attributes.email}</p>
      <p style={{ fontSize: "18px" }}>Documents</p>
      <div
        style={{
          display: "grid",
          flexDirection: "row",
          flexWrap: "wrap",
          gap: "5vw",
          gridTemplateColumns: "repeat(3,1fr)",
          gridTemplateRows: "min-content",
        }}
      >
        {attributes.visits?.data?.map((v) => {
          return (
            <Link
              key={v.attributes?.shopify_dress_id || "missing"}
              to={`/visit/${v.attributes?.id}`}
              style={{
                display: "flex",
                flexDirection: "column",
                justifyContent: "center",
                alignItems: "center",
                border: "1px solid pink",
                position: "relative",
                cursor: !v.attributes?.isPdfReady ? "not-allowed" : "",
                pointerEvents: !v.attributes?.isPdfReady ? "none" : "",
              }}
              onClick={(e) => {
                if (!v.attributes?.isPdfReady) e.preventDefault();
              }}
            >
              {v.attributes?.product?.imageUrl ? (
                <img
                  src={`${v?.attributes?.product?.imageUrl}&width=333`}
                  alt={v.attributes.product.title || "No title"}
                />
              ) : (
                <div>Image not available</div>
              )}
              <span>
                {v.attributes?.product?.title || "missing shopify data"}
              </span>
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
                    }}
                  >
                    PROCESSING
                  </p>
                </div>
              )}
            </Link>
          );
        })}
      </div>
    </div>
  );
}
