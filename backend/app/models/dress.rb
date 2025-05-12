class Dress < ApplicationRecord
    has_many_attached :images, dependent: :purge_later
    has_one :visit
end