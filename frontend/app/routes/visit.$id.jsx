import { useLoaderData, redirect } from "@remix-run/react";
// frontend/app/routes/visit.jsx
export async function loader({ params, request }) {
  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );

  const token = decodeURIComponent(cookies.token);
  const isAdmin = cookies.isAdmin;

  if (!token.includes("Bearer")) {
    return redirect("/login");
  }

  const res = await fetch(`https://df-pf.onrender.com/visits/${params.id}`, {
    headers: {
      Authorization: token,
    },
  });

  if (!res.ok) {
    const json = await res.json().catch(() => ({}));
    // If unauthorized, redirect to current user's page
    if (res.status === 401 || res.status === 403) {
      const currentUserId = json.user_id || "current"; // fallback just in case
      return redirect(`/user/${currentUserId}`);
    }

    // If other error and we know the visit's user, redirect there
    if (json.user_id) {
      return redirect(`/user/${json.user_id}`);
    }

    // Generic fallback
    throw new Response("Failed to fetch PDF", { status: res.status });
  }

  return await res.json();
}

export default function Visit() {
  const data = useLoaderData();
  console.log(data);

  return (
    <div className="user-visits-container">
      <div style={{ textAlign: "center", marginBottom: "2rem" }}>
        <p>{data.product?.title || "Untitled Dress"}</p>
        <p>{data.product?.price ? `$${data.product.price}` : ""}</p>
      </div>
      {data.images?.map((image) => (
        <img
          key={image.id}
          src={image.url}
          alt={image.filename}
          style={{
            width: "100%",
            maxWidth: "100%",
            height: "auto",
            objectFit: "cover",
          }}
        />
      ))}
    </div>
  );
}
