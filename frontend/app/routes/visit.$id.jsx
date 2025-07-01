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
  console.log("Visit data:", data);

  return (
    <>
      <div
        style={{ textAlign: "center", marginBottom: "2rem", marginTop: "6rem" }}
      >
        <p>{data.dress_name || "Untitled Dress"}</p>
        <p>{data.price || ""}</p>
      </div>
      <div className="user-visits-container">
        {data.images?.map((image) => (
          <div key={image.id}>
            {[".mov", ".mp4"].some((ext) =>
              image.filename.toLowerCase().endsWith(ext)
            ) ? (
              <video
                controls
                style={{
                  width: "100%",
                  maxWidth: "100%",
                  height: "auto",
                  objectFit: "cover",
                  aspectRatio: "1/1.333333",
                }}
              >
                <source src={image.url} type="video/mp4" />
                Your browser does not support the video tag.
              </video>
            ) : (
              <img
                src={image.url}
                alt={image.filename}
                style={{
                  width: "100%",
                  maxWidth: "100%",
                  height: "auto",
                  objectFit: "cover",
                }}
              />
            )}
          </div>
        ))}
      </div>
    </>
  );
}
