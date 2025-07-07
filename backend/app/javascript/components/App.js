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
  console.log(visits);

  return (
    <div>
      <VisitsForm />
      <VisitPdf visitId={86} />
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
        <p>No visits found</p>
      )}
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
        Client Name:
        <input
          type="text"
          value={customerName}
          onChange={(e) => setCustomerName(e.target.value)}
          required
        />
      </label>

      <br />

      <label>
        Client Email:
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
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Fetch visit data if needed for other reasons, but do not try to parse the PDF
    fetch(`/visits/${visitId}`)
      .then((res) => res.json())
      .then((data) => {
        // If you need to handle other data here
        setLoading(false);
      })
      .catch((err) => {
        console.error("Error fetching visit data:", err);
        setLoading(false);
      });
  }, [visitId]);

  const handleDownload = () => {
    // Fetch the visit PDF as a binary response
    fetch(`/visits/${visitId}`, {
      method: "GET",
      headers: {
        Accept: "application/pdf",
      },
    })
      .then((res) => {
        if (res.ok) {
          // Get the response as a blob
          return res.blob();
        } else {
          throw new Error("Failed to fetch PDF");
        }
      })
      .then((blob) => {
        // Create a URL for the blob and initiate a download
        const url = URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = url;
        link.download = `visit_${visitId}.pdf`; // Set the filename
        link.click();
        // Clean up the URL object
        URL.revokeObjectURL(url);
      })
      .catch((err) => console.error("Error downloading PDF:", err));
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <button onClick={handleDownload}>Download PDF</button>
    </div>
  );
}

export default Visits;
