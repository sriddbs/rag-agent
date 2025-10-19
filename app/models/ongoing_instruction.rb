class OngoingInstruction < ApplicationRecord
  validates :user_id, presence: true

  belongs_to :user

  scope :active, -> { where(active: true) }
end
