import { useEffect, useState } from "react";
import AutocompleteInput from "./AutocompleteInput";

export default function UserAutocomplete({
  userQuery,
  setUserQuery,
  selectedUser,
  setSelectedUser,
}) {
  const [userResults, setUserResults] = useState([]);

  useEffect(() => {
    if (userQuery.length < 1) setUserResults([]);
    if (userQuery.length < 2 || selectedUser) return;

    const fetchUsers = async () => {
      const res = await fetch(
        `/user-search?query=${encodeURIComponent(userQuery)}`
      );
      if (res.ok) {
        const { data } = await res.json();
        setUserResults(data.map((d) => d.attributes));
      }
    };

    const timeout = setTimeout(fetchUsers, 200);
    return () => clearTimeout(timeout);
  }, [userQuery, selectedUser]);

  return (
    <>
      <AutocompleteInput
        label="Search for User:"
        value={userQuery}
        onChange={(val) => {
          setUserQuery(val);
          setSelectedUser(null);
        }}
        placeholder="Start typing a name..."
        results={!selectedUser ? userResults : []}
        onSelect={(user) => {
          setSelectedUser(user);
          setUserQuery(user.name);
        }}
        renderItem={(u) => `${u.name} — ${u.email}`}
      />

      {selectedUser && (
        <>
          <input type="hidden" name="visit[user_id]" value={selectedUser.id} />
          <p>
            <strong>Selected User:</strong> {selectedUser.name} (
            {selectedUser.email})
          </p>
        </>
      )}
    </>
  );
}
