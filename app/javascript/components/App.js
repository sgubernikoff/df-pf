import React, { useEffect, useState } from "react";
import { Document, Page } from "react-pdf";

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
  console.log(visits);

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
      <VisitsForm />
      <VisitPdf visitId={11} />
    </div>
  );
};

const VisitsForm = () => {
  const [customerName, setCustomerName] = useState("");
  const [customerEmail, setCustomerEmail] = useState("");
  const [notes, setNotes] = useState("");
  const [dressIds, setDressIds] = useState([]);
  const [images, setImages] = useState([]);
  const [allDresses, setAllDresses] = useState([]);

  useEffect(() => {
    // Fetch all dresses to populate the form
    fetch("/dresses")
      .then((res) => res.json())
      .then((data) => {
        console.log(data);
        setAllDresses(data);
      })
      .catch((err) => console.error("Error fetching dresses:", err));
  }, []);

  const handleImageChange = (e) => {
    setImages(e.target.files);
  };

  const handleSubmit = (e) => {
    e.preventDefault();

    const formData = new FormData();
    formData.append("visit[customer_name]", customerName);
    formData.append("visit[customer_email]", customerEmail);
    formData.append("visit[notes]", notes);

    dressIds.forEach((id) => {
      formData.append("visit[dress_ids][]", id);
    });

    Array.from(images).forEach((file) => {
      formData.append("visit[images][]", file);
    });

    fetch("/visits", {
      method: "POST",
      body: formData,
    })
      .then((res) => {
        if (!res.ok) throw new Error("Failed to create visit");
        return res.json();
      })
      .then((data) => {
        console.log("Visit created:", data);
        alert("Visit submitted successfully!");
      })
      .catch((err) => {
        console.error(err);
        alert("There was an error submitting the form.");
      });
  };

  const handleDressSelection = (e) => {
    const value = e.target.value;
    setDressIds((prev) =>
      prev.includes(value)
        ? prev.filter((id) => id !== value)
        : [...prev, value]
    );
  };

  return (
    <form onSubmit={handleSubmit} encType="multipart/form-data">
      <h2>New Visit</h2>

      <label>
        Customer Name:
        <input
          type="text"
          value={customerName}
          onChange={(e) => setCustomerName(e.target.value)}
          required
        />
      </label>

      <br />

      <label>
        Customer Email:
        <input
          type="email"
          value={customerEmail}
          onChange={(e) => setCustomerEmail(e.target.value)}
        />
      </label>

      <br />

      <label>
        Notes:
        <textarea value={notes} onChange={(e) => setNotes(e.target.value)} />
      </label>

      <br />

      <fieldset>
        <legend>Select Dresses</legend>
        {allDresses.map((dress) => (
          <label key={dress.id}>
            <input
              type="checkbox"
              value={dress.id}
              checked={dressIds.includes(String(dress.id))}
              onChange={handleDressSelection}
            />
            {dress.name}
          </label>
        ))}
      </fieldset>

      <br />

      <label>
        Upload Images:
        <input type="file" multiple onChange={handleImageChange} />
      </label>

      <br />

      <button type="submit">Submit Visit</button>
    </form>
  );
};

function VisitPdf({ visitId }) {
  const [pdfData, setPdfData] = useState(null);

  useEffect(() => {
    fetch(`/visits/${visitId}`)
      .then((res) => res.json())
      .then((data) => {
        if (data.pdf) {
          setPdfData(data.pdf);
        }
      })
      .catch((err) => console.error("Error fetching PDF:", err));
  }, [visitId]);

  if (!pdfData) {
    return <div>Loading PDF...</div>;
  }

  return (
    <div>
      <Document file={`data:application/pdf;base64,${pdfData}`}>
        <Page pageNumber={1} />
      </Document>
    </div>
  );
}

export default Visits;
