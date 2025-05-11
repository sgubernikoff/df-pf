// app/utils/shopifyClient.server.js
const SHOPIFY_DOMAIN = process.env.SHOPIFY_STOREFRONT_API_ENDPOINT;
const SHOPIFY_TOKEN = process.env.SHOPIFY_STOREFRONT_API_TOKEN;

export async function fetchAllProductsFromCollection(handle) {
  let products = [];
  let hasNextPage = true;
  let cursor = null;

  while (hasNextPage) {
    const query = `
  query getProductsFromCollection($handle: String!, $cursor: String) @inContext(country: US, language: EN) {
    collection(handle: $handle) {
      products(first: 100, after: $cursor) {
        edges {
          cursor
          node {
            id
            title
            description
            images(first: 3){
                nodes{
                    url
                }
            }
            variants(first: 1) {
              edges {
                node {
                  price {
                    amount
                    currencyCode
                  }
                }
              }
            }
          }
        }
        pageInfo {
          hasNextPage
        }
      }
    }
  }
`;

    const res = await fetch(SHOPIFY_DOMAIN, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Shopify-Storefront-Access-Token": SHOPIFY_TOKEN,
      },
      body: JSON.stringify({ query, variables: { handle, cursor } }),
    });

    const json = await res.json();

    if (json.errors) {
      console.error("Shopify error:", json.errors);
      throw new Error("Failed to fetch products from Shopify");
    }

    const edges = json.data.collection.products.edges;
    products.push(
      ...edges.map((edge) => {
        const product = edge.node;
        const variant = product.variants.edges[0]?.node;
        return {
          id: product.id,
          title: product.title,
          price: variant?.price?.amount
            ? new Intl.NumberFormat("en-US", {
                style: "currency",
                currency: variant.price.currencyCode || "USD",
                maximumFractionDigits: 0,
              }).format(variant.price.amount)
            : null,
          images: product.images.nodes.map((img) => img.url).slice(0, 3),
          description: product.description,
        };
      })
    );

    hasNextPage = json.data.collection.products.pageInfo.hasNextPage;
    cursor = edges.at(-1)?.cursor;
  }
  console.log(products);
  return products;
}
