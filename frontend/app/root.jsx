import {
  Links,
  Meta,
  Outlet,
  Scripts,
  ScrollRestoration,
} from "@remix-run/react";

import Header from "./components/Header";
// import { json } from "@remix-run/node";
import { useLoaderData } from "@remix-run/react";
import { AuthProvider } from "./context/auth";
import ProtectedRoutes from "./components/ProtectedRoutes";

// Loader function to get user data based on session
// export async function loader({ request }) {
//   const userId = await getUserId(request);

//   // If the user is logged in (i.e., there's a userId), fetch the user's data
//   if (userId) {
//     const res = await fetch(`https://df-pf.onrender.com/users/${userId}`);
//     const user = await res.json();

//     // Return the user data as part of the loader's response
//     return json({ user });
//   }

//   // If there's no userId, return null for the user data
//   return json({ user: null });
// }

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
  ];
}

// Layout component to wrap the page's HTML structure
export function Layout({ children }) {
  return (
    <html lang="en">
      <head>
        <meta charSet="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
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
  return (
    <AuthProvider>
      <Header /> {/* Pass the user data to the Header component */}
      <main>
        <ProtectedRoutes>
          <Outlet /> {/* Render the child routes/content */}
        </ProtectedRoutes>
      </main>
    </AuthProvider>
  );
}
