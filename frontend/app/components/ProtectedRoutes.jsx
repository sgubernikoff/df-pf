// app/components/ProtectedRoutes.jsx
import { useEffect } from "react";
import { useLocation, useNavigate } from "@remix-run/react";
import { useContext } from "react";
import { AuthContext } from "../context/auth";

const PUBLIC_ROUTES = ["/login", "/signup"];

export default function ProtectedRoutes({ children }) {
  const { user, loading } = useContext(AuthContext);
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    if (!loading) {
      const isPublic = PUBLIC_ROUTES.includes(location.pathname);
      if (!user && !isPublic) {
        navigate("/login");
      }
    }
  }, [user, loading, location.pathname, navigate]);

  return children;
}
