import { pdfjs, Document, Page, Outline } from "react-pdf";
import { useLoaderData, redirect } from "@remix-run/react";
import { useRef, useState, useEffect } from "react";
import { useSize } from "ahooks";
import "react-pdf/dist/Page/AnnotationLayer.css";
import "react-pdf/dist/Page/TextLayer.css";
import Loader from "../components/Loader";
import ControlPanel from "../components/ControlPanel";

pdfjs.GlobalWorkerOptions.workerSrc = `//unpkg.com/pdfjs-dist@${pdfjs.version}/build/pdf.worker.min.mjs`;
const options = {
  cMapUrl: "/cmaps/",
};
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

  const res = await fetch(`https://localhost:3000/visits/${params.id}`, {
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
  const { pdf_base64 } = useLoaderData();
  const [isClient, setIsClient] = useState(false); // Ensure this renders only on the client
  const [scale, setScale] = useState(1.0);
  const [numPages, setNumPages] = useState(null);
  const [pageNumber, setPageNumber] = useState(1);
  const [isLoading, setIsLoading] = useState(true);
  const containerRef = useRef(null);
  const size = useSize(containerRef);
  const width = Math.min(size?.width || Infinity, 800); // Define maxWidth for rendering the PDF

  useEffect(() => {
    // This will run only on the client to disable SSR
    setIsClient(true);
  }, []);

  function onDocumentLoadSuccess({ numPages }) {
    setNumPages(numPages);
    setIsLoading(false);
  }

  if (!isClient) return null; // Return null while SSR is running

  return (
    <div
      ref={containerRef}
      style={{
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        minHeight: "100vh",
        width: "100%",
        overflow: "hidden",
        flexDirection: "column",
        paddingBlock: "6.5rem 4rem",
        background: "#d4e5e9",
      }}
    >
      <Document
        file={pdf_base64} // Use the file URL passed from the loader
        onLoadSuccess={onDocumentLoadSuccess}
        renderMode="canvas"
        options={options}
      >
        <Loader isLoading={isLoading} />
        <div
          style={{
            display: isLoading ? "none" : "block",
            transition: "all 300ms ease-in-out",
          }}
        >
          <Page
            pageNumber={pageNumber}
            width={width}
            scale={scale}
            onRenderSuccess={() => {
              setIsLoading(false);
            }}
          />
        </div>
      </Document>
      <ControlPanel
        scale={scale}
        setScale={setScale}
        numPages={numPages}
        pageNumber={pageNumber}
        setPageNumber={setPageNumber}
        load={() => setIsLoading(true)}
        file="/assets/docs/file-sample.pdf"
      />
    </div>
  );
}
