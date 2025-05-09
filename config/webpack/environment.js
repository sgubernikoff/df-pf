// config/webpack/environment.js
const { environment } = require("@rails/webpacker");
const babelLoader = environment.loaders.get("babel");

babelLoader.exclude = /node_modules\/(?!pdfjs-dist)/;

module.exports = environment;
