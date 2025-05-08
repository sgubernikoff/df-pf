# This file should ensure the existence of records required to run the application in every environment (production, development, test).
# The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
Visit.destroy_all
Dress.destroy_all

# Create Dresses first
dress1 = Dress.create!(
  name: "Red Dress",
  description: "A stunning red evening gown",
  price: 149.99
)

dress2 = Dress.create!(
  name: "Blue Dress",
  description: "A classy blue cocktail dress",
  price: 129.99
)

dress3 = Dress.create!(
  name: "Green Dress",
  description: "A refreshing green summer dress",
  price: 99.99
)

# Now create Visits and associate dresses
visit1 = Visit.create!(
  customer_name: "Alice Johnson",
  customer_email: "alice@example.com",
  notes: "Really liked the red dress.",
  dresses: [dress1]  # Associating dress1 with the visit
)

visit2 = Visit.create!(
  customer_name: "Beth Carter",
  customer_email: "beth@example.com",
  notes: "Torn between the blue and green dresses.",
  dresses: [dress2, dress3]  # Associating dress2 and dress3 with the visit
)

visit3 = Visit.create!(
  customer_name: "Charlie Smith",
  customer_email: "charlie@example.com",
  notes: "Loved the green dress, but went with the blue.",
  dresses: [dress2]  # Associating dress2 with the visit
)

visit4 = Visit.create!(
  customer_name: "Dana Williams",
  customer_email: "dana@example.com",
  notes: "The red dress was just perfect for the occasion!",
  dresses: [dress1]  # Associating dress1 with the visit
)

visit5 = Visit.create!(
  customer_name: "Eva Martinez",
  customer_email: "eva@example.com",
  notes: "Can't decide between the blue and green dresses. Both are beautiful!",
  dresses: [dress2, dress3]  # Associating dress2 and dress3 with the visit
)
