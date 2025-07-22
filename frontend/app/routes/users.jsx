import { Link, redirect, useLoaderData } from "@remix-run/react";
import { useRef, useState, useEffect } from "react";
import { useFetcher } from "react-router-dom";
import { Loading } from "../components/Loader";

export async function loader({ request }) {
  const url = new URL(request.url);
  const page = url.searchParams.get("page") || 1;
  const perPage = 20;

  const cookieHeader = request.headers.get("cookie");
  const cookies = Object.fromEntries(
    cookieHeader?.split("; ").map((c) => c.split("=")) ?? []
  );
  const token = decodeURIComponent(cookies.token || "");

  if (!token.includes("Bearer")) {
    return redirect("/login");
  }

  const res = await fetch(
    `https://df-pf.onrender.com/users?page=${page}&per_page=${perPage}`,
    {
      headers: {
        Authorization: token,
      },
    }
  );

  if (res.status === 401) {
    const { user_id } = await res.json();
    return redirect(`/user/${user_id}`);
  }

  if (!res.ok) {
    throw new Response("Failed to fetch users", { status: res.status });
  }

  const json = await res.json();
  return json;
}

function formatLatestVisit(visits) {
  if (!Array.isArray(visits) || visits.length === 0) return "No visits";
  const sorted = [...visits].sort(
    (a, b) =>
      new Date(b.attributes.created_at) - new Date(a.attributes.created_at)
  );
  const latest = new Date(sorted[0].attributes.created_at);
  return latest.toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export default function AdminUsersPage() {
  const { users: initialUsers, meta } = useLoaderData();
  const fetcher = useFetcher();
  const sentinelRef = useRef(null);
  const [users, setUsers] = useState(initialUsers?.data);
  const [page, setPage] = useState(meta.current_page);
  const [hasMore, setHasMore] = useState(meta.current_page < meta.total_pages);

  const [userQuery, setUserQuery] = useState(""); // Added query state
  const [filteredUsers, setFilteredUsers] = useState([]); // For search results
  const [isSearching, setIsSearching] = useState(false); // Flag for search state

  useEffect(() => {
    if (userQuery.length < 1) {
      setIsSearching(false);
      setFilteredUsers([]);
    } else {
      const fetchUsers = async () => {
        const res = await fetch(
          `/user-search?query=${encodeURIComponent(userQuery)}`
        );
        if (res.ok) {
          const { data } = await res.json();
          setFilteredUsers(data.map((d) => d.attributes));
          setIsSearching(true);
        }
      };

      const timeout = setTimeout(fetchUsers, 300);
      return () => clearTimeout(timeout);
    }
  }, [userQuery]);

  useEffect(() => {
    if (fetcher.data?.users) {
      setUsers((prev) => [...prev, ...fetcher.data.users]);
      setHasMore(
        fetcher.data.meta.current_page < fetcher.data.meta.total_pages
      );
    }
  }, [fetcher.data]);

  useEffect(() => {
    if (!hasMore) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && fetcher.state === "idle") {
          const nextPage = page + 1;
          fetcher.load(`/admin/users?page=${nextPage}`);
          setPage(nextPage);
        }
      },
      { threshold: 1.0 }
    );

    if (sentinelRef.current) {
      observer.observe(sentinelRef.current);
    }

    return () => observer.disconnect();
  }, [hasMore, page, fetcher]);

  return (
    <div
      className="users-page"
      style={{ display: "flex", flexDirection: "column", gap: "16px" }}
    >
      <p
        style={{
          fontSize: "12px",
          fontWeight: "bold",
          width: "100%",
          textAlign: "center",
        }}
      >
        Clients
      </p>

      {/* Search input */}
      <input
        type="text"
        value={userQuery}
        onChange={(e) => setUserQuery(e.target.value)}
        placeholder="Search for clients..."
        style={{
          padding: "8px",
          border: "1px solid #ddd",
          borderRadius: "0px",
          width: "100%",
          marginBottom: "16px",
        }}
      />

      {/* If searching, show search results */}
      {isSearching && filteredUsers.length > 0
        ? filteredUsers.map((user) => {
            const latestVisit = formatLatestVisit(user.visits?.data || []);
            return (
              <Link
                key={user.id}
                to={`/user/${user.id}`}
                style={{
                  padding: "16px",
                  border: "1px solid #ddd",
                  borderRadius: "0px",
                  textDecoration: "none",
                  color: "inherit",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "flex-start",
                }}
                className="user-page-link"
              >
                <div>
                  <p style={{ fontWeight: "600", marginBottom: "4px" }}>
                    {user.name}
                  </p>
                  <p style={{ color: "#555" }}>{user.email}</p>
                </div>
                <div
                  style={{
                    fontStyle: "italic",
                    color: "grey",
                    whiteSpace: "nowrap",
                    marginLeft: "16px",
                    flexShrink: 0,
                  }}
                >
                  {latestVisit}
                </div>
              </Link>
            );
          })
        : // If no search results, show paginated users
          users.map((user) => {
            const latestVisit = formatLatestVisit(
              user.attributes.visits?.data || []
            );
            return (
              <Link
                key={user.id}
                to={`/user/${user.id}`}
                style={{
                  padding: "16px",
                  border: "1px solid #ddd",
                  borderRadius: "0px",
                  textDecoration: "none",
                  color: "inherit",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "flex-start",
                }}
                className="user-page-link"
              >
                <div>
                  <p style={{ fontWeight: "600", marginBottom: "4px" }}>
                    {user.attributes.name}
                  </p>
                  <p style={{ color: "#555" }}>{user.attributes.email}</p>
                </div>
                <div
                  style={{
                    fontStyle: "italic",
                    color: "grey",
                    whiteSpace: "nowrap",
                    marginLeft: "16px",
                    flexShrink: 0,
                  }}
                >
                  {latestVisit}
                </div>
              </Link>
            );
          })}

      {/* Pagination if no search results */}
      {hasMore && !isSearching && (
        <div
          ref={sentinelRef}
          style={{
            height: "48px",
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
          }}
        >
          <Loading />
        </div>
      )}

      {!isSearching && !hasMore && users.length !== 0 && (
        <div style={{ fontStyle: "italic", color: "grey" }}></div>
      )}
    </div>
  );
}
