// app/components/Header.tsx
import { useState } from "react";
import logo from "../styles/DanielleFrankelMainLogo.jpg";
import "../styles/app.css";
import { useContext } from "react";
import { AuthContext } from "../context/auth";
import { NavLink, useLocation } from "@remix-run/react";
import { useEffect } from "react";

export default function Header() {
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
                New Salesperson
              </NavLink>
              <NavLink
                to="/visit/new"
                className="visits-link"
                style={{ color: "black", textDecoration: "none" }}
              >
                New Visit
              </NavLink>
              <NavLink
                to="/users"
                className="visits-link"
                style={{ color: "black", textDecoration: "none" }}
              >
                Users
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
              Log Out
            </button>
          ) : (
            <a href="/login">
              <button className="login-btn" style={{ border: "none" }}>
                Log In
              </button>
            </a>
          )}
        </div>
      </header>
      <MobileMenu open={open} />
    </>
  );
}

function MobileMenu({ open }) {
  return (
    <div className={`mobile-menu ${open ? "is-open" : ""}`}>
      <NavLink
        to="/visit/new"
        className="visits-link"
        style={{ color: "black", textDecoration: "none" }}
      >
        New Visit
      </NavLink>
      <NavLink
        to="/users"
        className="visits-link"
        style={{ color: "black", textDecoration: "none" }}
      >
        Users
      </NavLink>
      <NavLink
        to="/admin/new"
        className="visits-link"
        style={{ color: "black", textDecoration: "none" }}
      >
        New Salesperson
      </NavLink>
    </div>
  );
}
