class UserSerializer < ActiveModel::Serializer
include JSONAPI::Serializer
  attributes :id, :email, :name, :is_admin
end
