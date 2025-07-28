import { useEffect, useState } from "react";
import AutocompleteInput from "./AutocompleteInput";

export default function DressAutocomplete({
  shopifyData,
  selectedDress,
  setSelectedDress,
  labels,
}) {
  const [dressQuery, setDressQuery] = useState("");

  const filtered =
    dressQuery.length > 0
      ? shopifyData.filter((d) =>
          d.title.toLowerCase().includes(dressQuery.toLowerCase())
        )
      : [];

  return (
    <fieldset>
      <legend>Select A Dress</legend>
      <AutocompleteInput
        label={labels?.label || "Select a dress:"}
        value={dressQuery}
        onChange={(val) => {
          setDressQuery(val);
          setSelectedDress(null);
        }}
        placeholder={labels?.placeholder || "Start typing..."}
        results={!selectedDress ? filtered : []}
        onSelect={(dress) => {
          setSelectedDress(dress);
          setDressQuery(dress.title);
        }}
        renderItem={(d) => `${d.title}`}
      />

      <input
        type="hidden"
        name="visit[selected_dress]"
        value={selectedDress ? JSON.stringify(selectedDress) : "{}"}
      />

      {selectedDress && (
        <div style={{ marginTop: 8 }}>
          <strong>Selected:</strong> {selectedDress.title}
          <br />
          <img
            src={selectedDress.images?.[0]}
            alt={selectedDress.title}
            width={100}
          />
        </div>
      )}
    </fieldset>
  );
}
