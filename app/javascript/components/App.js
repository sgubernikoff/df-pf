import React, { useEffect, useState } from "react";

const Visits = () => {
  const [visits, setVisits] = useState([]);

  useEffect(() => {
    // Fetch visits data in JSON format
    fetch("/visits")
      .then((response) => {
        // Ensure the response is in JSON format
        if (!response.ok) {
          throw new Error("Network response was not ok");
        }
        return response.json();
      })
      .then((data) => {
        // Set the state with fetched data
        setVisits(data);
      })
      .catch((error) => {
        console.error("There was an error fetching the visits:", error);
      });
  }, []);

  return (
    <div>
      <h1>Visits</h1>
      {visits.length > 0 ? (
        visits.map((visit) => (
          <div key={visit.id}>
            <h2>{visit.customer_name}</h2>
            <p>{visit.notes}</p>
            <ul>
              {visit.dresses.map((dress) => (
                <li key={dress.id}>{dress.name}</li>
              ))}
            </ul>
          </div>
        ))
      ) : (
        <p>No visits found.</p>
      )}
    </div>
  );
};

export default Visits;
