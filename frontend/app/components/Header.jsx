// app/components/Header.tsx
import { Form, useLoaderData } from "@remix-run/react";
import logo from "../styles/DanielleFrankelMainLogo.jpg";
import "../styles/app.css";

export default function Header() {
  const { user } = useLoaderData();

  return (
    <header className="header">
      <div>{""}</div>
      <div className="logo">
        <img
          src={logo}
          alt="Logo"
          className="logo-img"
          style={{ width: "20%" }}
        />
      </div>
      <div className="auth">
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
