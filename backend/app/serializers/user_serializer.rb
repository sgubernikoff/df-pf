# app/serializers/user_serializer.rb
class UserSerializer
  include JSONAPI::Serializer

  attributes :id, :email, :name, :is_admin, :visits

  attribute :visits do |user|
    VisitSerializer.new(user.visits.order(id: :desc)).serializable_hash
  end
end
