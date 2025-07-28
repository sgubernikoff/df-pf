import {
  Links,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
} from "@remix-run/react";

import Header from "./components/Header";
import { json } from "@remix-run/node";
import { useLoaderData, useLocation } from "@remix-run/react";
import { AuthProvider } from "./context/auth";
import ProtectedRoutes from "./components/ProtectedRoutes";
import favicon from "./styles/favicon.png";
import { client } from "./sanity/SanityClient";

export async function loader({}) {
  const settings = await client
    .fetch(`*[_type == "settings"][0]`)
    .then((r) => r);
  console.log(settings);
  return json(settings);
}

// Links function to preconnect to external resources and load styles
export function links() {
  return [
    { rel: "preconnect", href: "https://fonts.googleapis.com" },
    {
      rel: "preconnect",
      href: "https://fonts.gstatic.com",
      crossOrigin: "anonymous",
    },
    {
      rel: "stylesheet",
      href: "https://fonts.googleapis.com/css2?family=Inter:ital,opsz,wght@0,14..32,100..900;1,14..32,100..900&display=swap",
    },
    { rel: "icon", type: "image/jpg", href: favicon },
  ];
}

// Layout component to wrap the page's HTML structure
export function Layout({ children }) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta
          property="og:image"
          content="http://www.daniellefrankelstudio.com/cdn/shop/files/DF_LOOK15_MAEVE4_af0df745-7c84-4dfa-9857-f7cde1d5a535.jpg?v=1712079302"
        />
        <Meta />
        <Links />
      </head>
      <body>
        {children}
        <ScrollRestoration />
        <Scripts />
      </body>
    </html>
  );
}

// Main App component that renders the header and page content
export default function App() {
  const location = useLocation();
  const publicPaths = ["/reset-password", "/login", "/signup"];
  const isPublic = publicPaths.some((path) =>
    location.pathname.startsWith(path)
  );

  const { header } = useLoaderData();

  return (
    <AuthProvider>
      <Header labels={header} />
      <main>
        {isPublic ? (
          <Outlet />
        ) : (
          <ProtectedRoutes>
            <Outlet />
          </ProtectedRoutes>
        )}
      </main>
    </AuthProvider>
  );
}
