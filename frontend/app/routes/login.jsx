// app/routes/login.jsx
import { useState, useContext } from "react";
import { useNavigate } from "@remix-run/react";
import { AuthContext } from "../context/auth";
import "../styles/app.css";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [showResetForm, setShowResetForm] = useState(false);
  const [resetEmail, setResetEmail] = useState("");
  const [resetSent, setResetSent] = useState(false);
  const [resetLoading, setResetLoading] = useState(false);
  const [resetError, setResetError] = useState("");

  const { login } = useContext(AuthContext);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");

    const user = await login(email, password);
    if (user?.id) {
      if (user?.is_admin) navigate("/visit/new");
      else navigate(`/user/${user.id}`);
    } else {
      setError("Invalid credentials");
    }
  };

  const handleForgotPassword = () => {
    setShowResetForm(true);
    setResetEmail(email); // Pre-fill with login email if available
    setError(""); // Clear any login errors
  };

  const handleResetSubmit = async (e) => {
    e.preventDefault();
    setResetLoading(true);
    setResetError("");
    try {
      const response = await fetch(
        "https://df-pf.onrender.com/users/manual_password_reset",
        {
          method: "POST",
          credentials: "include",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            user: {
              email: resetEmail,
            },
          }),
        }
      );

      const data = await response.json();

      if (response.ok) {
        setResetSent(true);
      } else {
        setResetError(data.errors?.[0] || "Failed to send reset email");
      }
    } catch (error) {
      console.error("Password reset request failed:", error);
      setResetError("Network error. Please try again.");
    } finally {
      setResetLoading(false);
    }
  };

  const handleBackToLogin = () => {
    setShowResetForm(false);
    setResetSent(false);
    setResetEmail("");
    setResetError("");
  };

  // Reset password form
  if (showResetForm) {
    return (
      <div className="login-page">
        {!resetSent ? (
          <>
            <p>Reset Your Password</p>

            {resetError && <p className="error">{resetError}</p>}

            <form onSubmit={handleResetSubmit}>
              <div>
                <label htmlFor="resetEmail">Email</label>
                <input
                  type="email"
                  id="resetEmail"
                  value={resetEmail}
                  onChange={(e) => setResetEmail(e.target.value)}
                  required
                  disabled={resetLoading}
                />
              </div>
              <div className="button-group">
                <button
                  type="submit"
                  disabled={resetLoading}
                  className="primary-button"
                >
                  {resetLoading ? "Sending..." : "Send Reset Link"}
                </button>
                <button
                  type="button"
                  onClick={handleBackToLogin}
                  className="secondary-button"
                  disabled={resetLoading}
                >
                  Back to Login
                </button>
              </div>
            </form>
          </>
        ) : (
          <div className="reset-success">
            <div className="success-icon">📧</div>
            <p>Check Your Email</p>
            <p className="success-message">
              We've sent a password reset link to <strong>{resetEmail}</strong>
            </p>
            <p className="success-instructions">
              Click the link in your email to reset your password. If you don't
              see the email, check your spam folder.
            </p>
            <div className="button-group">
              <button onClick={handleBackToLogin} className="primary-button">
                Back to Login
              </button>
              <button
                onClick={() => handleResetSubmit({ preventDefault: () => {} })}
                className="secondary-button"
                disabled={resetLoading}
              >
                {resetLoading ? "Sending..." : "Resend Email"}
              </button>
            </div>
          </div>
        )}
      </div>
    );
  }

  // Regular login form
  return (
    <div className="login-page">
      <p>Login</p>
      {error && <p className="error">{error}</p>}
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="email">Email</label>
          <input
            type="email"
            id="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />
        </div>
        <div>
          <label htmlFor="password">Password</label>
          <input
            type="password"
            id="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </div>
        <button type="submit" className="primary-button">
          Login
        </button>
      </form>

      <div className="login-footer">
        <button
          type="button"
          onClick={handleForgotPassword}
          className="forgot-password-link"
        >
          Forgot your password?
        </button>
      </div>
    </div>
  );
}
