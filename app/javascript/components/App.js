import React, { useEffect, useState } from "react";

const Visits = () => {
  const [visits, setVisits] = useState([]);

  useEffect(() => {
    fetch("/api/v1/posts")
      .then((response) => response.json())
      .then((data) => setVisits(data));
  }, []);

  return (
    <div>
      {visits.map((visit) => (
        <div key={visit.id}>{visit.title}</div>
      ))}
    </div>
  );
};

export default Visits;
