class UserSerializer 
include JSONAPI::Serializer
  attributes :id, :email, :name, :is_admin
end
