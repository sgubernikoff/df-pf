class Dress < ApplicationRecord
    has_many_attached :images, dependent: :purge_later
    has_and_belongs_to_many :visits
end