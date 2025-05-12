// app/components/Header.tsx
import { Form } from "@remix-run/react";
import logo from "../styles/DanielleFrankelMainLogo.jpg";
import "../styles/app.css";
import { useContext } from "react";
import { AuthContext } from "../context/auth";

export default function Header() {
  const { user, logout } = useContext(AuthContext);

  return (
    <header className="header">
      <div className="header-left"></div>
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
  );
}
