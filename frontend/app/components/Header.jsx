// app/components/Header.tsx
import { useState } from "react";
import logo from "../styles/DanielleFrankelMainLogo.jpg";
import "../styles/app.css";
import { useContext } from "react";
import { AuthContext } from "../context/auth";
import { NavLink, useLocation } from "@remix-run/react";
import { useEffect } from "react";

export default function Header({ labels }) {
  const { user, logout } = useContext(AuthContext);
  const [open, setIsOpen] = useState(false);
  function toggleIsOpen() {
    setIsOpen(!open);
  }
  const { pathname } = useLocation();
  useEffect(() => setIsOpen(false), [pathname]);

  return (
    <>
      <header className="header">
        <div className="header-left">
          {user?.is_admin && <button onClick={toggleIsOpen}>☰</button>}
        </div>
        <div className="logo">
          <NavLink to="/" className="logo-link">
            <img src={logo} alt="Logo" className="logo-img" />
          </NavLink>
        </div>
        <div className="auth">
          {user?.is_admin && (
            <>
              <NavLink
                to="/admin/new"
                className="visits-link"
                style={{ color: "black", textDecoration: "none" }}
              >
                {labels?.new_salesperson || "New Salesperson"}
              </NavLink>
              <NavLink
                to="/visit/new"
                className="visits-link"
                style={{ color: "black", textDecoration: "none" }}
              >
                {labels?.new_visit || "New Visit"}
              </NavLink>
              <NavLink
                to="/users"
                className="visits-link"
                style={{ color: "black", textDecoration: "none" }}
              >
                {labels?.clients || "Clients"}
              </NavLink>
            </>
          )}
          {user ? (
            <button
              type="submit"
              className="logout-btn"
              style={{ border: "none", padding: "0" }}
              onClick={logout}
            >
              {labels?.log_out || "Log Out"}
            </button>
          ) : (
            <a href="/login">
              <button className="login-btn" style={{ border: "none" }}>
                {labels?.log_in || "Log In"}
              </button>
            </a>
          )}
        </div>
      </header>
      <MobileMenu open={open} labels={labels} />
    </>
  );
}

function MobileMenu({ open, labels }) {
  return (
    <div className={`mobile-menu ${open ? "is-open" : ""}`}>
      <NavLink
        to="/visit/new"
        className="visits-link"
        style={{ color: "black", textDecoration: "none" }}
      >
        {labels?.new_visit || "New Visit"}
      </NavLink>
      <NavLink
        to="/users"
        className="visits-link"
        style={{ color: "black", textDecoration: "none" }}
      >
        {labels?.clients || "Clients"}
      </NavLink>
      <NavLink
        to="/admin/new"
        className="visits-link"
        style={{ color: "black", textDecoration: "none" }}
      >
        {labels?.new_salesperson || "New Salesperson"}
      </NavLink>
    </div>
  );
}
