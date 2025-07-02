// app/components/Header.tsx
import { useState } from "react";
import logo from "../styles/DanielleFrankelMainLogo.jpg";
import "../styles/app.css";
import { useContext } from "react";
import { AuthContext } from "../context/auth";

export default function Header() {
  const { user, logout } = useContext(AuthContext);
  const [open, setIsOpen] = useState(false);
  function toggleIsOpen() {
    setIsOpen(!open);
  }

  return (
    <>
      <header className="header">
        <div className="header-left">
          {user?.is_admin && <button onClick={toggleIsOpen}>☰</button>}
        </div>
        <div className="logo">
          <a href="/" className="logo-link">
            <img src={logo} alt="Logo" className="logo-img" />
          </a>
        </div>
        <div className="auth">
          {user?.is_admin && (
            <>
              <a
                href="/visit/new"
                className="visits-link"
                style={{ color: "black", textDecoration: "none" }}
              >
                New Visit
              </a>
              <a
                href="/users"
                className="visits-link"
                style={{ color: "black", textDecoration: "none" }}
              >
                Users
              </a>
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
      <a
        href="/visit/new"
        className="visits-link"
        style={{ color: "black", textDecoration: "none" }}
      >
        New Visit
      </a>
      <a
        href="/users"
        className="visits-link"
        style={{ color: "black", textDecoration: "none" }}
      >
        Users
      </a>
    </div>
  );
}
