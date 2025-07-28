import { useState, useContext } from "react";
import { useLocation, useNavigate } from "@remix-run/react";
import { AuthContext } from "../context/auth";

export default function ResetPassword() {
  const location = useLocation();
  const navigate = useNavigate();
  const searchParams = new URLSearchParams(location.search);
  const token = searchParams.get("token");

  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  const { login } = useContext(AuthContext);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    if (password !== confirm) {
      setError("Passwords don't match");
      return;
    }

    setLoading(true);
    try {
      const res = await fetch("https://df-pf.onrender.com/users/password", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user: {
            reset_password_token: token,
            password,
            password_confirmation: confirm,
          },
        }),
      });

      let data;
      const contentType = res.headers.get("content-type");
      if (contentType && contentType.includes("application/json")) {
        data = await res.json();
      } else {
        data = { error: await res.text() };
      }

      if (!res.ok) {
        const message =
          data?.errors?.full_messages?.[0] ||
          data?.error ||
          "Failed to reset password";
        throw new Error(message);
      }

      setSuccess(true);
      console.log(data);
      const record = data.data || data.user || {}; // capture user record from response

      const user = await login(record.email, password);
      if (user?.id) {
        if (user?.is_admin) navigate("/visit/new");
        else navigate(`/user/${user.id}`);
      } else {
        setError("Invalid credentials");
      }
    } catch (err) {
      setError(err.message || "Something went wrong");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-page">
      <p>Set Your Password</p>
      {success ? null : ( // <p>Password successfully updated! You can now log in.</p>
        <form onSubmit={handleSubmit}>
          <div>
            <label>New Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>
          <div>
            <label>Confirm Password</label>
            <input
              type="password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              required
            />
          </div>
          <button type="submit" disabled={loading}>
            {loading ? "Submitting..." : "Reset Password"}
          </button>
          {error && <p style={{ color: "red" }}>{error}</p>}
        </form>
      )}
    </div>
  );
}
