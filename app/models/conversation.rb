class Conversation < ApplicationRecord
  belongs_to :user

  has_many :messages, dependent: :destroy
  has_many :tasks, dependent: :nullify

  def add_message(role, content, metadata = {})
    messages.create!(role:, content:, metadata:)
  end
end
