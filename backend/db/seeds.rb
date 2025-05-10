# This file should ensure the existence of records required to run the application in every environment (production, development, test).
# The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
puts "\e[33mClearing existing records...\e[0m"
Visit.destroy_all
Dress.destroy_all
User.destroy_all  # Clearing existing users
puts "\e[32mExisting records cleared.\e[0m"

# Create Users first
puts "\e[34mCreating Users...\e[0m"

user1 = User.create!(
  name: "Alice Johnson",
  email: "alice@example.com",
  password: "password123"
)
puts "\e[32mCreated User: #{user1.name} (#{user1.email})\e[0m"

user2 = User.create!(
  name: "Beth Carter",
  email: "beth@example.com",
  password: "password123"
)
puts "\e[32mCreated User: #{user2.name} (#{user2.email})\e[0m"

user3 = User.create!(
  name: "Charlie Smith",
  email: "charlie@example.com",
  password: "password123"
)
puts "\e[32mCreated User: #{user3.name} (#{user3.email})\e[0m"

user4 = User.create!(
  name: "Dana Williams",
  email: "dana@example.com",
  password: "password123"
)
puts "\e[32mCreated User: #{user4.name} (#{user4.email})\e[0m"

user5 = User.create!(
  name: "Eva Martinez",
  email: "eva@example.com",
  password: "password123"
)
puts "\e[32mCreated User: #{user5.name} (#{user5.email})\e[0m"

# Create Dresses first
puts "\e[34mCreating Dresses...\e[0m"

dress1 = Dress.create!(
  name: "Red Dress",
  description: "A stunning red evening gown",
  price: 149.99
)
puts "\e[32mCreated Red Dress: #{dress1.name}\e[0m"

dress2 = Dress.create!(
  name: "Blue Dress",
  description: "A classy blue cocktail dress",
  price: 129.99
)
puts "\e[32mCreated Blue Dress: #{dress2.name}\e[0m"

dress3 = Dress.create!(
  name: "Green Dress",
  description: "A refreshing green summer dress",
  price: 99.99
)
puts "\e[32mCreated Green Dress: #{dress3.name}\e[0m"

# Now create Visits and associate dresses with users
puts "\e[34mCreating Visits and associating dresses with users...\e[0m"

visit1 = Visit.create!(
  notes: "Really liked the red dress.",
  dresses: [dress1],  # Associating dress1 with the visit
  user: user1         # Associating visit with user1
)
puts "\e[32mCreated Visit for User: #{user1.name} with Dress: #{dress1.name}\e[0m"

visit2 = Visit.create!(
  notes: "Torn between the blue and green dresses.",
  dresses: [dress2, dress3],  # Associating dress2 and dress3 with the visit
  user: user2               # Associating visit with user2
)
puts "\e[32mCreated Visit for User: #{user2.name} with Dresses: #{dress2.name}, #{dress3.name}\e[0m"

visit3 = Visit.create!(
  notes: "Loved the green dress, but went with the blue.",
  dresses: [dress2],  # Associating dress2 with the visit
  user: user3         # Associating visit with user3
)
puts "\e[32mCreated Visit for User: #{user3.name} with Dress: #{dress2.name}\e[0m"

visit4 = Visit.create!(
  notes: "The red dress was just perfect for the occasion!",
  dresses: [dress1],  # Associating dress1 with the visit
  user: user4         # Associating visit with user4
)
puts "\e[32mCreated Visit for User: #{user4.name} with Dress: #{dress1.name}\e[0m"

visit5 = Visit.create!(
  notes: "Can't decide between the blue and green dresses. Both are beautiful!",
  dresses: [dress2, dress3],  # Associating dress2 and dress3 with the visit
  user: user5               # Associating visit with user5
)
puts "\e[32mCreated Visit for User: #{user5.name} with Dresses: #{dress2.name}, #{dress3.name}\e[0m"

puts "\e[33mAll records created successfully!\e[0m"
