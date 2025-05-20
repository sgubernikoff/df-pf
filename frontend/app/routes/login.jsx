// app/routes/login.jsx
import { useState, useContext } from "react";
import { useNavigate } from "@remix-run/react";
import { AuthContext } from "../context/auth";
import "../styles/app.css";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
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
        <button type="submit">Login</button>
      </form>
    </div>
  );
}
