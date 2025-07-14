# Essential production data
admin_user = User.find_or_create_by(email: "admin@df.com") do |user|
  user.name = "Admin User"
  user.password = ENV['ADMIN_PASSWORD']
  user.password_confirmation = ENV['ADMIN_PASSWORD']
  user.is_admin = true
  user.office = 'NY'
  user.title = 'Salesperson'
  user.phone = '555.555.5555'
end

puts "\e[35;1m🚨 Admin User Created: #{admin_user.name} (#{admin_user.email}) — is_admin: #{admin_user.is_admin}\e[0m" if admin_user&.persisted?

# Skip development/test seeds in production
return if Rails.env.production?

# Clear existing data
puts "\e[33mClearing existing records...\e[0m"
Visit.destroy_all
Dress.destroy_all
User.destroy_all  # Clearing existing users
puts "\e[32m✔ Existing records cleared.\e[0m"

# Create Users first
puts "\e[34mCreating Users...\e[0m"

user1 = User.create!(
  name: "Alice Johnson",
  email: "alice@example.com",
  password: "password123", password_confirmation: "password123",
  is_admin: false
)
puts "\e[32m✔ Created User: #{user1.name} (#{user1.email})\e[0m"

user2 = User.create!(
  name: "Beth Carter",
  email: "beth@example.com",
  password: "password123", password_confirmation: "password123",
  is_admin: false
)
puts "\e[32m✔ Created User: #{user2.name} (#{user2.email})\e[0m"

user3 = User.create!(
  name: "Charlie Smith",
  email: "charlie@example.com",
  password: "password123", password_confirmation: "password123",
  is_admin: false
)
puts "\e[32m✔ Created User: #{user3.name} (#{user3.email})\e[0m"

user4 = User.create!(
  name: "Dana Williams",
  email: "dana@example.com",
  password: "password123", password_confirmation: "password123",
  is_admin: false
)
puts "\e[32m✔ Created User: #{user4.name} (#{user4.email})\e[0m"

user5 = User.create!(
  name: "Eva Martinez",
  email: "eva@example.com",
  password: "password123", password_confirmation: "password123",
  is_admin: false
)
puts "\e[32m✔ Created User: #{user5.name} (#{user5.email})\e[0m"

admin_user = User.find_or_create_by(email: "admin@df.com") do |user|
  user.name = "Admin User"
  user.password = "adminpass123"
  user.password_confirmation = "adminpass123"
  user.is_admin = true
  user.office = 'NY'
  user.title = 'Salesperson'
  user.phone = '555.555.5555'
end
puts "\e[35;1m🚨 Admin User Created: #{admin_user.name} (#{admin_user.email}) — is_admin: #{admin_user.is_admin}\e[0m" if admin_user&.persisted?

# Link clients to salesperson
puts "\e[34mAssigning clients to salesperson...\e[0m"
UserAssignment.create!(
  salesperson: admin_user,
  client: user1
)
puts "\e[32m✔ Assigned User: #{user1.name} to #{admin_user.name}\e[0m"
UserAssignment.create!(
  salesperson: admin_user,
  client: user2
)
puts "\e[32m✔ Assigned User: #{user2.name} to #{admin_user.name}\e[0m"
UserAssignment.create!(
  salesperson: admin_user,
  client: user3
)
puts "\e[32m✔ Assigned User: #{user3.name} to #{admin_user.name}\e[0m"
UserAssignment.create!(
  salesperson: admin_user,
  client: user4
)
puts "\e[32m✔ Assigned User: #{user4.name} to #{admin_user.name}\e[0m"
UserAssignment.create!(
  salesperson: admin_user,
  client: user5
)
puts "\e[32m✔ Assigned User: #{user5.name} to #{admin_user.name}\e[0m"

# Create Dresses
puts "\e[34mCreating Dresses...\e[0m"

dress1 = Dress.create!(
  name: "Red Dress",
  description: "A stunning red evening gown",
  price: 149.99,
  image_urls: ["https://via.placeholder.com/500x750/ff0000/ffffff?text=Red+Dress"]
)
puts "\e[32m✔ Created Dress: #{dress1.name}\e[0m"

dress2 = Dress.create!(
  name: "Blue Dress",
  description: "A classy blue cocktail dress",
  price: 129.99,
  image_urls: ["https://via.placeholder.com/500x750/ff0000/ffffff?text=Red+Dress"]
)
puts "\e[32m✔ Created Dress: #{dress2.name}\e[0m"

dress3 = Dress.create!(
  name: "Green Dress",
  description: "A refreshing green summer dress",
  price: 99.99,
  image_urls: ["https://via.placeholder.com/500x750/ff0000/ffffff?text=Red+Dress"] 
)
puts "\e[32m✔ Created Dress: #{dress3.name}\e[0m"

# Create Visits
puts "\e[34mCreating Visits and associating dresses with users...\e[0m"

visit1 = Visit.create!(
  notes: "Really liked the red dress.",
  dress: dress1,
  user: user1,
  images: [
    {
      io: File.open(Rails.root.join('public/images/DanielleFrankelMainLogo.jpg')),
      filename: 'DanielleFrankelMainLogo.jpg',
      content_type: 'image/jpeg'
    }
  ]
)
puts "\e[32m✔ Created Visit for #{user1.name} with Dress: #{dress1.name}\e[0m"

visit2 = Visit.create!(
  notes: "Torn between the blue and green dresses.",
  dress: dress2,
  user: user2,
  images: [
    {
      io: File.open(Rails.root.join('public/images/DanielleFrankelMainLogo.jpg')),
      filename: 'DanielleFrankelMainLogo.jpg',
      content_type: 'image/jpeg'
    }
  ]
)
puts "\e[32m✔ Created Visit for #{user2.name} with Dresses: #{dress2.name}, #{dress3.name}\e[0m"

visit3 = Visit.create!(
  notes: "Loved the green dress, but went with the blue.",
  dress: dress2,
  user: user3,
  images: [
    {
      io: File.open(Rails.root.join('public/images/DanielleFrankelMainLogo.jpg')),
      filename: 'DanielleFrankelMainLogo.jpg',
      content_type: 'image/jpeg'
    }
  ]
)
puts "\e[32m✔ Created Visit for #{user3.name} with Dress: #{dress2.name}\e[0m"

visit4 = Visit.create!(
  notes: "The red dress was just perfect for the occasion!",
  dress: dress1,
  user: user4,
  images: [
    {
      io: File.open(Rails.root.join('public/images/DanielleFrankelMainLogo.jpg')),
      filename: 'DanielleFrankelMainLogo.jpg',
      content_type: 'image/jpeg'
    }
  ]
)
puts "\e[32m✔ Created Visit for #{user4.name} with Dress: #{dress1.name}\e[0m"

visit5 = Visit.create!(
  notes: "Can't decide between the blue and green dresses. Both are beautiful!",
  dress: dress2,
  user: user5,
  images: [
    {
      io: File.open(Rails.root.join('public/images/DanielleFrankelMainLogo.jpg')),
      filename: 'DanielleFrankelMainLogo.jpg',
      content_type: 'image/jpeg'
    }
  ]
)
puts "\e[32m✔ Created Visit for #{user5.name} with Dresses: #{dress2.name}, #{dress3.name}\e[0m"

puts "\e[36;1m✅ All records created successfully!\e[0m"
