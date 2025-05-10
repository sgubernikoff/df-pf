import React, { useEffect, useState } from "react";

function Loader({ isLoading }) {
  if (!isLoading) return null;

  return (
    <div
      id="loader"
      style={{
        display: "flex",
        justifyContent: "center",
        alignItems: "center",
        flexDirection: "column",
      }}
    >
      <img
        src="/figuresLogo.png"
        alt="loader"
        style={{
          animation: "pulse 2.8s infinite ease-in-out", // Pulse effect for image
        }}
      />
      <Loading />
      <style>{`
        @keyframes pulse {
          0% {
            opacity: 0.19;
          }
          50% {
            opacity: 0;
          }
          100% {
            opacity: .2;
          }
        }
      `}</style>
    </div>
  );
}

function Loading() {
  const [index, setIndex] = useState(13);
  const loading = "...Loading...";
  const loadingArray = loading.split("");

  useEffect(() => {
    let timer = setTimeout(() => {
      if (index > -13) setIndex(index - 1);
      else if (index === -13) setIndex(12);
    }, 111);

    return function cleanup() {
      clearTimeout(timer);
    };
  });

  return (
    <div
      style={{
        position: "fixed",
        top: "50%",
        left: "50%",
        transform: "translate(-50%,-50%)",
        margin: "auto",
        width: "fit-content",
      }}
    >
      <h4
        style={{
          display: "block",
          margin: "auto",
          marginTop: 20,
          marginBottom: 20,
          width: "fit-content",
          fontFamily: "Arial, sans-serif",
          fontSize: "20px",
        }}
      >
        {loadingArray.splice(index)}
        {loadingArray}
      </h4>
    </div>
  );
}

export default Loader;
