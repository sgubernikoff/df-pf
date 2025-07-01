# app/serializers/visit_serializer.rb
class VisitSerializer
  include JSONAPI::Serializer

  attributes :id, :created_at, :shopify_dress_id, :price, :processed
  
end
