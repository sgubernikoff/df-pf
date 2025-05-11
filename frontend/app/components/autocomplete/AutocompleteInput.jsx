import { useEffect, useState } from "react";

export default function AutocompleteInput({
  label,
  value,
  onChange,
  placeholder,
  results,
  onSelect,
  renderItem,
}) {
  return (
    <label>
      {label}
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        autoComplete="off"
      />
      {results.length > 0 && (
        <ul style={{ border: "1px solid #ccc", marginTop: 4, padding: 4 }}>
          {results.map((item, idx) => (
            <li
              key={idx}
              style={{ cursor: "pointer", padding: 4 }}
              onClick={() => onSelect(item)}
            >
              {renderItem(item)}
            </li>
          ))}
        </ul>
      )}
    </label>
  );
}
