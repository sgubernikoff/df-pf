import React from "react";

const ControlPanel = (props) => {
  const { pageNumber, numPages, setPageNumber, scale, setScale, load } = props;

  const isFirstPage = pageNumber === 1;
  const isLastPage = pageNumber === numPages;

  const isMinZoom = scale < 0.6;
  const isMaxZoom = scale >= 2.0;

  const colorVisible = "#f0f0f0";
  const colorDisabled = "rgba(240, 240, 240, 0.3)";

  const buttonStyle = {
    margin: "0 6px",
    fontSize: "1.2rem",
    background: "none",
    border: "none",
    color: colorVisible,
    cursor: "pointer",
  };

  const disabledButtonStyle = {
    ...buttonStyle,
    color: colorDisabled,
    cursor: "not-allowed",
  };

  const spanStyle = {
    margin: "0 8px",
    color: colorVisible,
  };

  const inputStyle = {
    padding: "0.25rem",
    margin: "0 0.5rem",
    width: "3rem",
    backgroundColor: "#222",
    color: colorVisible,
    border: "1px solid #444",
    borderRadius: "4px",
  };

  const containerStyle = {
    margin: "1rem",
    padding: "1rem",
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    flexWrap: "wrap",
    backgroundColor: "#000",
    position: "fixed",
    top: "1rem",
    zIndex: 2,
  };

  const groupStyle = {
    display: "flex",
    alignItems: "center",
  };

  const goToFirstPage = () => {
    if (!isFirstPage) {
      setPageNumber(1);
      load();
    }
  };
  const goToPreviousPage = () => {
    if (!isFirstPage) {
      setPageNumber(pageNumber - 1);
      load();
    }
  };
  const goToNextPage = () => {
    if (!isLastPage) {
      setPageNumber(pageNumber + 1);
      load();
    }
  };
  const goToLastPage = () => {
    if (!isLastPage) {
      setPageNumber(numPages);
      load();
    }
  };
  const onPageChange = (e) => {
    const { value } = e.target;
    setPageNumber(Number(value));
  };
  const zoomOut = () => {
    if (!isMinZoom) setScale(scale - 0.1);
  };
  const zoomIn = () => {
    if (!isMaxZoom) setScale(scale + 0.1);
  };

  return (
    <div style={containerStyle}>
      <div style={groupStyle}>
        <button
          style={isFirstPage ? disabledButtonStyle : buttonStyle}
          onClick={goToFirstPage}
          disabled={isFirstPage}
          title="First page"
        >
          ⏮️
        </button>
        <button
          style={isFirstPage ? disabledButtonStyle : buttonStyle}
          onClick={goToPreviousPage}
          disabled={isFirstPage}
          title="Previous page"
        >
          ◀️
        </button>
        <span style={spanStyle}>
          Page{" "}
          <input
            name="pageNumber"
            type="number"
            min={1}
            max={numPages || 1}
            style={inputStyle}
            value={pageNumber}
            onChange={onPageChange}
          />{" "}
          of {numPages}
        </span>
        <button
          style={isLastPage ? disabledButtonStyle : buttonStyle}
          onClick={goToNextPage}
          disabled={isLastPage}
          title="Next page"
        >
          ▶️
        </button>
        <button
          style={isLastPage ? disabledButtonStyle : buttonStyle}
          onClick={goToLastPage}
          disabled={isLastPage}
          title="Last page"
        >
          ⏭️
        </button>
      </div>
      <div style={groupStyle}>
        <button
          style={isMinZoom ? disabledButtonStyle : buttonStyle}
          onClick={zoomOut}
          disabled={isMinZoom}
          title="Zoom out"
        >
          ⊖
        </button>
        <span style={spanStyle}>{(scale * 100).toFixed()}%</span>
        <button
          style={isMaxZoom ? disabledButtonStyle : buttonStyle}
          onClick={zoomIn}
          disabled={isMaxZoom}
          title="Zoom in"
        >
          ⊕
        </button>
      </div>
    </div>
  );
};

export default ControlPanel;
