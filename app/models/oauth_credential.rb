class OauthCredential < ApplicationRecord
  validates :user_id, presence: true
  validates :provider, presence: true
 
  belongs_to :user
end
