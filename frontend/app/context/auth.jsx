// app/context/auth.jsx
import { createContext, useState, useEffect } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import { useNavigate } from "@remix-run/react";

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const token = Cookies.get("token");
    if (token) {
      checkAuth(token);
    } else {
      setLoading(false);
    }
  }, []);

  const checkAuth = async (token) => {
    try {
      // Set default Authorization header for all requests
      axios.defaults.headers.common["Authorization"] = token;
      axios.defaults.headers.common["Content-Type"] = `application/json`;
      const response = await axios.get("http://localhost:3000//current_user");
      setUser(response.data.data);
      Cookies.set("isAdmin", response.data.data.is_admin);
    } catch (error) {
      Cookies.remove("token");
      Cookies.remove("isAdmin");
    } finally {
      setLoading(false);
    }
  };

  const login = async (email, password) => {
    try {
      const response = await axios.post("http://localhost:3000//login", {
        user: { email, password },
      });

      const { authorization } = response.headers;
      Cookies.set("token", authorization, { expires: 7 });
      axios.defaults.headers.common["Authorization"] = authorization;
      setUser(response.data.data);
      Cookies.set("isAdmin", response.data.data.is_admin);
      return response.data.data;
    } catch (error) {
      return false;
    }
  };

  const logout = async () => {
    try {
      const response = await axios.delete("http://localhost:3000//logout", {
        Method: "DELETE",
      });

      if (response.status === 200) {
        Cookies.remove("token");
        Cookies.remove("isAdmin");
        delete axios.defaults.headers.common["Authorization"];
        setUser(null);
      }
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  );
};
