class Task < ApplicationRecord
  belongs_to :user
  belongs_to :conversation, optional: true

  STATUSES = %w(pending in_progress waiting completed failed).freeze

  validates :status, inclusion: { in: STATUSES }

  scope :active, -> { where(status: %w(pending in_progress waiting)) }
  scope :pending, -> { where(status: 'pending') }
end
