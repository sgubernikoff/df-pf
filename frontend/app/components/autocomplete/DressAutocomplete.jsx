import { useEffect, useState } from "react";
import AutocompleteInput from "./AutocompleteInput";

export default function DressAutocomplete({
  shopifyData,
  selectedDress,
  setSelectedDress,
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
        label="Select a dress:"
        value={dressQuery}
        onChange={(val) => {
          setDressQuery(val);
          setSelectedDress(null);
        }}
        placeholder="Start typing..."
        results={!selectedDress ? filtered : []}
        onSelect={(dress) => {
          console.log("Selected dress raw:", dress);
          console.log("First variant price:", dress.variants?.[0]?.price);

          const enrichedDress = {
            ...dress,
            price: `$${parseFloat(dress.variants?.[0]?.price || 0).toFixed(2)}`,
          };

          setSelectedDress(enrichedDress);
          setDressQuery(dress.title);
        }}
        renderItem={(d) => `${d.title}`}
      />

      {selectedDress && (
        <>
          <input
            type="hidden"
            name="visit[selected_dress]"
            value={JSON.stringify(selectedDress)}
          />
          <div style={{ marginTop: 8 }}>
            <strong>Selected:</strong> {selectedDress.title}
            <br />
            <img
              src={selectedDress.images?.[0]}
              alt={selectedDress.title}
              width={100}
            />
          </div>
        </>
      )}
    </fieldset>
  );
}
