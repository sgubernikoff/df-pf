import { vitePlugin as remix } from "@remix-run/dev";
import { defineConfig, normalizePath } from "vite";
import tsconfigPaths from "vite-tsconfig-paths";
import { viteStaticCopy } from "vite-plugin-static-copy";
import path from "node:path";
import { createRequire } from "node:module";

declare module "@remix-run/node" {
  interface Future {
    v3_singleFetch: true;
  }
}

const require = createRequire(import.meta.url);
const pdfjsDistPath = path.dirname(require.resolve("pdfjs-dist/package.json"));
const cMapsDir = normalizePath(path.join(pdfjsDistPath, "cmaps"));

export default defineConfig({
  plugins: [
    remix({
      future: {
        v3_fetcherPersist: true,
        v3_relativeSplatPath: true,
        v3_throwAbortReason: true,
        v3_singleFetch: true,
        v3_lazyRouteDiscovery: true,
      },
    }),
    tsconfigPaths(),
    viteStaticCopy({
      targets: [
        {
          src: cMapsDir,
          dest: "pdfjs-dist",
        },
      ],
    }),
  ],
});
