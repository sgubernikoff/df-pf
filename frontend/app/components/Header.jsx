// app/components/Header.tsx
import { Form, useLoaderData } from "@remix-run/react";
import logo from "../styles/DanielleFrankelMainLogo.jpg";
import "../styles/app.css";

export default function Header() {
  const { user } = useLoaderData();

  return (
    <header className="header">
      <div className="header-left"></div>
      <div className="logo">
        <a href="/" className="logo-link">
          <img
            src={logo}
            alt="Logo"
            className="logo-img"
            style={{ width: "20%" }}
          />
        </a>
      </div>
      <div className="auth">
        {user && (
          <a
            href="/visits"
            className="visits-link"
            style={{ color: "black", textDecoration: "none" }}
          >
            Visits
          </a>
        )}
        {user ? (
          <Form method="post" action="/logout">
            {" "}
            {/* Submit to /logout */}
            <button
              type="submit"
              className="logout-btn"
              style={{ border: "none", padding: "0" }}
            >
              Log Out
            </button>
          </Form>
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
