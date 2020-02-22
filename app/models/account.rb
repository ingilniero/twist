class Account < ApplicationRecord
  belongs_to :owner, class_name: "User"
  accepts_nested_attributes_for :owner

  validates :subdomain, presence: true, uniqueness: true

  has_many :memberships
  has_many :users, through: :memberships
  has_many :invitations
end
